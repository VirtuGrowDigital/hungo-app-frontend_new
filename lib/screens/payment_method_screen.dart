import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/wallet_controller.dart';
import '../utils/ColorConstants.dart';
import 'order_success_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String? addressId;
  final String address;
  final String fulfillmentType;
  final double? lat;
  final double? lng;

  const PaymentMethodScreen({
    super.key,
    this.addressId,
    required this.address,
    required this.fulfillmentType,
    this.lat,
    this.lng,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final OrderController orderController = Get.find<OrderController>();
  final CartController cartController = Get.find<CartController>();
  final WalletController walletController = Get.find<WalletController>();
  final RxInt selectedMethod = 1.obs;
  final RxBool useWallet = true.obs;
  Worker? _paymentCompletedWorker;

  @override
  void initState() {
    super.initState();
    walletController.fetchWallet();
    cartController.fetchCart(type: widget.fulfillmentType);

    _paymentCompletedWorker =
        ever(orderController.paymentCompleted, (bool completed) {
      if (completed && mounted) {
        orderController.paymentCompleted.value = false;
        Get.offAll(() => const OrderSuccessScreen());
      }
    });
  }

  @override
  void dispose() {
    _paymentCompletedWorker?.dispose();
    super.dispose();
  }

  String _money(num value) => "₹${value.toStringAsFixed(0)}";

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !orderController.isLoading.value,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop || !orderController.isLoading.value) return;
          Get.snackbar(
            "Please Wait",
            "Payment is in progress",
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Payment Method"),
            centerTitle: true,
          ),
          body: Obx(() {
            final walletBalance = walletController.wallet.value?.balance ?? 0.0;
            final totalAmount = cartController.totalAmount.value;
            final walletApplied =
                useWallet.value ? walletBalance.clamp(0.0, totalAmount) : 0.0;
            final payableAmount =
                (totalAmount - walletApplied).clamp(0.0, totalAmount);
            final isWalletOnly = walletApplied > 0 && payableAmount == 0;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  // Shipping Address Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fulfillmentType == "SELF_PICKUP"
                                ? "Pickup Type"
                                : "Shipping Address",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.fulfillmentType == "SELF_PICKUP"
                                ? "You will collect this order yourself."
                                : widget.address,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Card(
                    elevation: 1,
                    child: SwitchListTile(
                      value: useWallet.value && walletBalance > 0,
                      activeThumbColor: ColorConstants.success,
                      secondary: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: ColorConstants.success,
                      ),
                      title: Text(
                        walletBalance > 0
                            ? "Use Hungzo Wallet"
                            : "Hungzo Wallet",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        walletBalance > 0
                            ? "Available ${_money(walletBalance)}. Applying ${_money(walletApplied)}."
                            : "No wallet balance available for this order.",
                      ),
                      onChanged:
                          orderController.isLoading.value || walletBalance <= 0
                              ? null
                              : (value) => useWallet.value = value,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffEAECF0)),
                    ),
                    child: Column(
                      children: [
                        _amountRow("Order total", totalAmount),
                        const SizedBox(height: 8),
                        _amountRow("Wallet used", -walletApplied),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        _amountRow("Pay now", payableAmount, highlight: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (isWalletOnly) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xffECFDF3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xffABEFC6)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: ColorConstants.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Wallet covers this order",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xff067647),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Your Hungzo Wallet will pay the full ${_money(totalAmount)}. No extra payment method is needed.",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xff344054),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Text(
                      "Select Payment Method",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Online Payment Option
                    Card(
                      elevation: 1,
                      child: RadioListTile<int>(
                        title: const Text("Online Payment"),
                        subtitle: Text(
                          walletApplied > 0
                              ? "Pay remaining ${_money(payableAmount)} via UPI, Card, Wallet"
                              : "Pay via UPI, Card, Wallet",
                        ),
                        secondary:
                            const Icon(Icons.payment, color: Colors.green),
                        value: 1,
                        groupValue: selectedMethod.value,
                        onChanged: orderController.isLoading.value
                            ? null
                            : (int? v) {
                                if (v != null) selectedMethod.value = v;
                              },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Cash on Delivery Option
                    Card(
                      elevation: 1,
                      child: RadioListTile<int>(
                        title: const Text("Cash on Delivery"),
                        subtitle: Text(
                          walletApplied > 0
                              ? "Pay remaining ${_money(payableAmount)} when you receive"
                              : "Pay when you receive",
                        ),
                        secondary:
                            const Icon(Icons.money, color: Colors.orange),
                        value: 2,
                        groupValue: selectedMethod.value,
                        onChanged: orderController.isLoading.value
                            ? null
                            : (int? v) {
                                if (v != null) selectedMethod.value = v;
                              },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Place Order Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: orderController.isLoading.value
                          ? null
                          : () {
                              orderController.placeOrder(
                                addressId: widget.addressId,
                                shippingAddress: widget.address,
                                paymentMethod: selectedMethod.value == 1
                                    ? "ONLINE"
                                    : "COD",
                                fulfillmentType: widget.fulfillmentType,
                                useWallet: useWallet.value,
                                lat: widget.lat,
                                lng: widget.lng,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: orderController.isLoading.value
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text("Processing..."),
                              ],
                            )
                          : Text(
                              isWalletOnly
                                  ? "Place Wallet Order"
                                  : selectedMethod.value == 1
                                      ? "Pay ${_money(payableAmount)}"
                                      : "Place Order",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _amountRow(
    String label,
    double value, {
    bool highlight = false,
  }) {
    final isNegative = value < 0;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: highlight ? 15 : 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color:
                  highlight ? const Color(0xff101828) : const Color(0xff667085),
            ),
          ),
        ),
        Text(
          "${isNegative ? "-" : ""}${_money(value.abs())}",
          style: TextStyle(
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
            color:
                isNegative ? ColorConstants.success : const Color(0xff101828),
          ),
        ),
      ],
    );
  }
}
