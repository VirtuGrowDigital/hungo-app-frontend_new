import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hungzo_app/services/Api/api_constants.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';
import 'my_orders_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;
  final OrderItem selectedItem;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    required this.selectedItem,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen>
    with TickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late List<AnimationController> _controllers;
  late final List<String> statusFlow;

  late int currentIndex;

  bool get _canShowCancel {
    final status = widget.order.orderStatus;
    return status != "Cancelled" &&
        status != "Delivered" &&
        status != "Picked by Customer";
  }

  @override
  void initState() {
    super.initState();

    statusFlow = _buildStatusFlow();

    final item = widget.selectedItem;
    String effectiveStatus = widget.order.orderStatus;

    if (item.returned && !item.refunded) {
      effectiveStatus = "Returned";
    }

    if (item.refunded) {
      effectiveStatus = "Refunded";
    }

    currentIndex = statusFlow.indexOf(effectiveStatus);

    _controllers = List.generate(
      statusFlow.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );

    if (currentIndex >= 0) {
      _playSequential(currentIndex);
    }
  }

  Future<void> _playSequential(int endIndex) async {
    for (int i = 0; i <= endIndex; i++) {
      await _controllers[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = widget.order.orderStatus == "Cancelled";

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Order Details",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        actions: [
          if (_canShowCancel)
            TextButton(
              onPressed: _showCancelDialog,
              child: const Text(
                "Cancel Order",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadInvoice,
          ),
        ],
      ),
      body: ListView(
        children: [
          _productHeader(),
          _orderOverviewCard(),
          if (!widget.order.isDelivery && widget.order.warehouseAssignment != null)
            _pickupWarehouseCard(),
          if (widget.selectedItem.refunded) _refundCard(),
          const SizedBox(height: 10),
          if (isCancelled) _cancelledCard() else _timelineCard(),
        ],
      ),
    );
  }

  // ================= DOWNLOAD INVOICE =================

  Future<void> _downloadInvoice() async {
    try {
      final order = widget.order;

      final pdf = pw.Document();

      // Load logo
      final logoBytes =
          await rootBundle.load('assets/logo/hunzo_main_logo.png');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // Download product image (first item)
      pw.MemoryImage? productImage;

      if (order.items.isNotEmpty && order.items.first.image.isNotEmpty) {
        final response = await http.get(Uri.parse(order.items.first.image));
        productImage = pw.MemoryImage(response.bodyBytes);
      }

      final double subTotal = order.subTotal > 0
          ? order.subTotal
          : order.items.fold(0, (sum, item) => sum + item.total);
      final double deliveryFee = order.deliveryCharge;
      final double platformFee = order.platformFee;
      final double gstAmount = order.gstAmount;
      final double grandTotal = order.totalAmount > 0
          ? order.totalAmount
          : subTotal + deliveryFee + platformFee + gstAmount;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                /// HEADER
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logoImage, height: 60),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "INVOICE",
                          style: pw.TextStyle(
                            fontSize: 26,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          "Date: ${DateFormat('dd MMM yyyy').format(DateTime.parse(order.createdAt).toLocal())}",
                        ),
                        pw.Text("Order ID: ${order.id}"),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 20),

                /// PRODUCT TABLE
                pw.Text(
                  "Order Items",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    /// TABLE HEADER
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.blue50),
                      children: [
                        _tableCell("Product"),
                        _tableCell("Qty"),
                        _tableCell("Price"),
                        _tableCell("Total"),
                      ],
                    ),

                    /// TABLE ROWS
                    ...order.items.map(
                      (item) => pw.TableRow(
                        children: [
                          _tableCell(item.name),
                          _tableCell(item.qty.toString()),
                          _tableCell("₹${item.price}"),
                          _tableCell("₹${item.total}"),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 25),

                /// PRODUCT IMAGE
                if (productImage != null) ...[
                  pw.Text(
                    "Product Image",
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Image(productImage, height: 100),
                  pw.SizedBox(height: 20),
                ],

                pw.Divider(),

                pw.SizedBox(height: 15),

                /// SUMMARY
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _summaryRow("Subtotal", subTotal),
                      _summaryRow("Delivery Fee", deliveryFee),
                      _summaryRow("Platform Fee", platformFee),
                      if (gstAmount > 0) _summaryRow("GST", gstAmount),
                      pw.SizedBox(height: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          "Grand Total: ₹$grandTotal",
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),
                pw.Divider(),

                pw.Center(
                  child: pw.Text(
                    "Thank you for shopping with us!",
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/invoice_${order.id}.pdf");

      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice saved successfully")),
      );

      await OpenFile.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// ================= TABLE CELL HELPER =================
  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  pw.Widget _summaryRow(String title, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title),
          pw.Text("₹$value"),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final token = await _storage.read(key: 'accessToken');

    if (token == null) return;

    final response = await http.patch(
      Uri.parse("${ApiConstants.baseURL}orders/${widget.order.id}/cancel"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    final body =
        response.body.isEmpty ? null : jsonDecode(response.body) as Map<String, dynamic>;
    final message =
        body?["message"]?.toString() ??
        (response.statusCode == 200
            ? "Order cancelled successfully"
            : "Unable to cancel order");

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (response.statusCode == 200) {
      if (Get.isRegistered<OrdersController>()) {
        await Get.find<OrdersController>().fetchOrders();
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text(
          "You can cancel this order only before it is delivered or picked up. Do you want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Keep Order"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder();
            },
            child: const Text("Cancel Order"),
          ),
        ],
      ),
    );
  }

  // ================= UI CARDS & STEPPER =================

  Widget _productHeader() {
    final item = widget.selectedItem;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                  )
                : _placeholderImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text("Qty: ${item.qty}",
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Text("Order #${widget.order.id}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _cancelledCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Order Cancelled",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.order.statusDescriptionFor("Cancelled"),
            style: const TextStyle(color: Colors.redAccent),
          ),
          if (widget.order.cancelledAtDate != null) ...[
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a')
                  .format(widget.order.cancelledAtDate!),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _orderOverviewCard() {
    final order = widget.order;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.displayStatus,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusPill(order.displayStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.statusDescriptionFor(order.displayStatus),
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(Icons.payments_outlined, order.paymentStatusLabel),
              _infoChip(Icons.local_shipping_outlined, order.fulfillmentLabel),
              _infoChip(
                Icons.currency_rupee,
                "₹${order.totalAmount.toStringAsFixed(0)}",
              ),
            ],
          ),
          if (order.driverStatus == "DRIVER_ACCEPTED" &&
              order.displayStatus == "Packed") ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Driver assigned. Pickup will begin shortly.",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _refundCard() {
    final item = widget.selectedItem;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Refund Processed",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text("Refund Amount - ₹${item.refundAmount.toInt()}"),
        ],
      ),
    );
  }

  Widget _pickupWarehouseCard() {
    final warehouse = widget.order.warehouseAssignment!;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.store_mall_directory_outlined),
              SizedBox(width: 8),
              Text(
                "Pickup Warehouse",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            warehouse.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            warehouse.fullAddress,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          if (warehouse.latitude != null && warehouse.longitude != null) ...[
            const SizedBox(height: 8),
            Text(
              "Coordinates: ${warehouse.latitude}, ${warehouse.longitude}",
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (warehouse.mapLink.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.map_outlined, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          warehouse.mapLink,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showNavigationOptions(warehouse),
                        icon: const Icon(Icons.navigation_outlined, size: 18),
                        label: const Text("Navigate to Warehouse"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    if (warehouse.mapLink.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: warehouse.mapLink),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Google Maps link copied"),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text("Copy"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNavigationOptions(WarehouseAssignment warehouse) async {
    final googleMapsUri = _buildGoogleMapsUri(warehouse);
    final appleMapsUri = _buildAppleMapsUri(warehouse);

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        final isIOS = Platform.isIOS;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Open pickup location",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  warehouse.name,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                if (isIOS) ...[
                  _mapOptionTile(
                    icon: Icons.map_outlined,
                    title: "Open in Apple Maps",
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await _launchMapUri(appleMapsUri);
                    },
                  ),
                  _mapOptionTile(
                    icon: Icons.pin_drop_outlined,
                    title: "Open in Google Maps",
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await _launchMapUri(googleMapsUri);
                    },
                  ),
                ] else ...[
                  _mapOptionTile(
                    icon: Icons.pin_drop_outlined,
                    title: "Open in Google Maps",
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await _launchMapUri(googleMapsUri);
                    },
                  ),
                  _mapOptionTile(
                    icon: Icons.public,
                    title: "Open map link",
                    onTap: () async {
                      Navigator.pop(bottomSheetContext);
                      await _launchMapUri(Uri.parse(warehouse.mapLink));
                    },
                  ),
                ],
                _mapOptionTile(
                  icon: Icons.copy,
                  title: "Copy map link",
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await Clipboard.setData(
                      ClipboardData(text: warehouse.mapLink),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Google Maps link copied")),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mapOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Uri _buildGoogleMapsUri(WarehouseAssignment warehouse) {
    if (warehouse.latitude != null && warehouse.longitude != null) {
      return Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=${warehouse.latitude},${warehouse.longitude}",
      );
    }

    final query = Uri.encodeComponent(
      warehouse.fullAddress.isNotEmpty ? warehouse.fullAddress : warehouse.name,
    );
    return Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$query",
    );
  }

  Uri _buildAppleMapsUri(WarehouseAssignment warehouse) {
    final query = Uri.encodeComponent(
      warehouse.fullAddress.isNotEmpty ? warehouse.fullAddress : warehouse.name,
    );

    if (warehouse.latitude != null && warehouse.longitude != null) {
      return Uri.parse(
        "http://maps.apple.com/?ll=${warehouse.latitude},${warehouse.longitude}&q=$query",
      );
    }

    return Uri.parse("http://maps.apple.com/?q=$query");
  }

  Future<void> _launchMapUri(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open map location")),
      );
    }
  }

  Widget _timelineCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Order Status",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Column(
            children: List.generate(statusFlow.length, (index) {
              final stepStatus = statusFlow[index];
              final isActive = currentIndex >= 0 && index <= currentIndex;
              final isLast = index == statusFlow.length - 1;
              final stepTime = _timelineDate(stepStatus);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedBuilder(
                        animation: _controllers[index],
                        builder: (_, __) {
                          return Container(
                            height: 14,
                            width: 14,
                            decoration: BoxDecoration(
                              color: _controllers[index].value > 0
                                  ? Colors.green
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      if (!isLast)
                        SizedBox(
                          height: 50,
                          width: 2,
                          child: Stack(
                            children: [
                              Container(
                                  height: 50,
                                  width: 2,
                                  color: Colors.grey.shade300),
                              Container(
                                  height: 50 * _controllers[index].value,
                                  width: 2,
                                  color: Colors.green),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepStatus,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.black : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.order.statusDescriptionFor(stepStatus),
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? Colors.black54 : Colors.grey,
                              height: 1.35,
                            ),
                          ),
                          if (stepTime != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('dd MMM yyyy, hh:mm a').format(stepTime),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  List<String> _buildStatusFlow() {
    final item = widget.selectedItem;
    final baseFlow = widget.order.customerStatusFlow;

    if (item.refunded) {
      return [...baseFlow, "Returned", "Refunded"];
    }

    if (item.returned) {
      return [...baseFlow, "Returned"];
    }

    return baseFlow;
  }

  DateTime? _timelineDate(String status) {
    if (status == "Returned" || status == "Refunded") {
      return widget.order.deliveredAtDate ?? widget.order.updatedAtDate;
    }

    return widget.order.timelineTimeFor(status);
  }
}

Widget _placeholderImage() {
  return Container(
    height: 70,
    width: 70,
    color: Colors.grey.shade200,
    child: const Icon(
      Icons.image_not_supported,
      color: Colors.grey,
    ),
  );
}

Widget _statusPill(String status) {
  final (Color background, Color foreground, IconData icon) = switch (status) {
    "Delivered" => (Colors.green.withValues(alpha: 0.12), Colors.green, Icons.check_circle),
    "Picked by Customer" => (Colors.teal.withValues(alpha: 0.12), Colors.teal, Icons.storefront),
    "Out for Delivery" => (Colors.blue.withValues(alpha: 0.12), Colors.blue, Icons.local_shipping),
    "Packed" => (Colors.orange.withValues(alpha: 0.12), Colors.orange, Icons.inventory),
    "Accepted" => (Colors.deepPurple.withValues(alpha: 0.12), Colors.deepPurple, Icons.verified),
    "Cancelled" => (Colors.red.withValues(alpha: 0.12), Colors.red, Icons.cancel),
    _ => (Colors.grey.withValues(alpha: 0.14), Colors.grey, Icons.access_time),
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: 6),
        Text(
          status,
          style: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _infoChip(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
