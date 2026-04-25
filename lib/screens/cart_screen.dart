import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hungzo_app/screens/payment_method_screen.dart';
import 'package:hungzo_app/screens/select_location_screen.dart';
import 'package:shimmer/shimmer.dart';

import '../bindings/home_binding.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../utils/ColorConstants.dart';
import '../utils/ImageConstant.dart';
import 'home_view.dart';
import 'widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final CartController controller = Get.find<CartController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        title: const Text('Your Cart'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Obx(() {
        if (!authController.isSessionReady.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!authController.isLoggedIn.value) {
          return _guestCartView();
        }

        if (controller.isLoading.value && controller.cartItems.isEmpty) {
          return _cartShimmer();
        }

        if (controller.cartItems.isEmpty) {
          return _emptyCartView(context);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: RefreshIndicator(
            onRefresh: () => controller.fetchCart(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 10),
              children: [
                Obx(() => _topInfoPanel()),
                const SizedBox(height: 10),
                ...controller.cartItems.map(
                  (item) => CartItemTile(
                    item: item,
                    controller: controller,
                  ),
                ),
                const SizedBox(height: 8),
                _checkoutPanel(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _cartShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade200,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyCartView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 220,
            child: Image.asset(ImageConstant.emptyCart),
          ),
          const SizedBox(height: 20),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: "Your Cart is "),
                TextSpan(
                  text: "Empty",
                  style: TextStyle(color: Colors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Add item to get started",
            style: TextStyle(color: Colors.grey),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Get.offAll(
                  () => const HomeView(),
                  binding: HomeBinding(),
                );
              },
              child: const Text(
                'Go back to home',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _guestCartView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 220,
            child: Image.asset(ImageConstant.emptyCart),
          ),
          const SizedBox(height: 24),
          const Text(
            "Login to use your cart",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            "Browse products freely. Sign in only when you're ready to save items and checkout.",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorConstants.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                authController.ensureAuthenticated(
                  title: 'Login to access cart',
                  message:
                      'Please log in to save items in your cart and continue to checkout.',
                );
              },
              child: const Text(
                'Login to continue',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Get.offAll(
                () => const HomeView(),
                binding: HomeBinding(),
              );
            },
            child: const Text('Keep browsing'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _topInfoPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE8EDF3)),
      ),
      child: Column(
        children: [
          _fulfillmentSelector(),
          const SizedBox(height: 8),
          _addressSection(),
        ],
      ),
    );
  }

  Widget _fulfillmentSelector() {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _fulfillmentOption(
              title: 'Delivery',
              subtitle: 'Send to your address',
              icon: Icons.local_shipping_outlined,
              selected: controller.fulfillmentType.value ==
                  CartController.deliveryType,
              onTap: () => controller.setFulfillmentType(
                CartController.deliveryType,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _fulfillmentOption(
              title: 'Self Pickup',
              subtitle: 'Collect from store',
              icon: Icons.storefront_outlined,
              selected: controller.fulfillmentType.value ==
                  CartController.selfPickupType,
              onTap: () => controller.setFulfillmentType(
                CartController.selfPickupType,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fulfillmentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? ColorConstants.success : const Color(0xffF2F4F7),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: selected ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressSection() {
    if (controller.isSelfPickup) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: const Row(
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 18,
              color: ColorConstants.success,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Pickup selected. You will collect this order from the store.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xff667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final address = controller.selectedDeliveryAddress.value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.location_on_outlined,
            size: 18,
            color: ColorConstants.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address == null ? 'Delivery address not selected' : address.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff101828),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address == null
                    ? 'Choose where the order should be delivered.'
                    : address.fullAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: Color(0xff667085),
                ),
              ),
              if (address?.receiverPhone != null &&
                  address!.receiverPhone!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    address.receiverPhone!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xff344054),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 34,
          child: OutlinedButton(
            onPressed: _selectDeliveryAddress,
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.success,
              side: const BorderSide(color: ColorConstants.success),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              address == null ? 'Choose' : 'Change',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDeliveryAddress() async {
    final selected = await Get.to<Map<String, dynamic>>(
      () => const SelectLocationScreen(
        fulfillmentType: CartController.deliveryType,
        returnSelection: true,
      ),
    );

    if (selected == null) return;

    controller.setSelectedDeliveryAddress(
      CartDeliveryAddress.fromJson(selected),
    );
  }

  Widget _checkoutPanel() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffE8EDF3)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D101828),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff667085),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${controller.totalAmount.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff101828),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Inclusive of fees shown below',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xff667085),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xffF4FBF8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    controller.isSelfPickup ? 'Self Pickup' : 'Delivery',
                    style: const TextStyle(
                      color: ColorConstants.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _summaryRow('Subtotal', controller.subtotal.value),
                  const SizedBox(height: 10),
                  _summaryRow(
                    controller.isSelfPickup ? 'Pickup Fee' : 'Delivery Fee',
                    controller.deliveryFee.value,
                  ),
                  const SizedBox(height: 10),
                  _summaryRow('Platform Fee', controller.platformFee.value),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, thickness: 1, color: Color(0xffE4E7EC)),
                  ),
                  _summaryRow(
                    'To Pay',
                    controller.totalAmount.value,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffEAECF0)),
              ),
              child: CheckboxListTile(
                value: controller.deliveryVerificationAccepted.value,
                activeColor: ColorConstants.success,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                dense: true,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                title: const Text(
                  "Verify items on delivery. Delivered orders aren't returnable.",
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.2,
                    color: Color(0xff344054),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onChanged: (value) => controller
                    .setDeliveryVerificationAccepted(value ?? false),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.deliveryVerificationAccepted.value
                      ? ColorConstants.success
                      : Colors.grey.shade400,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: controller.deliveryVerificationAccepted.value
                    ? () {
                        if (controller.isSelfPickup) {
                          Get.to(
                            () => const PaymentMethodScreen(
                              address: 'SELF PICKUP',
                              fulfillmentType: CartController.selfPickupType,
                            ),
                          );
                          return;
                        }

                        final address = controller.selectedDeliveryAddress.value;
                        if (address == null) {
                          _selectDeliveryAddress();
                          return;
                        }

                        Get.to(
                          () => PaymentMethodScreen(
                            addressId: address.addressId,
                            address: address.fullAddress,
                            fulfillmentType: CartController.deliveryType,
                            lat: address.latitude,
                            lng: address.longitude,
                          ),
                        );
                      }
                    : null,
                child: const Text(
                  'Proceed to Payment',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    double value, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: highlight ? 14.5 : 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? const Color(0xff101828) : const Color(0xff667085),
            ),
          ),
        ),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: highlight ? 18 : 14,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w700,
            color: const Color(0xff101828),
          ),
        ),
      ],
    );
  }
}
