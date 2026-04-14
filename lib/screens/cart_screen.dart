import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hungzo_app/screens/select%20_location%20_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/cart_controller.dart';
import '../utils/ColorConstants.dart';
import '../utils/ImageConstant.dart';
import 'home_view.dart';
import '../bindings/home_binding.dart';
import 'widgets/cart_item_tile.dart';

class CartScreen extends StatelessWidget {
  CartScreen({super.key});

  final CartController controller = Get.put(CartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        title: const Text('Your Cart',style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Obx(() {
        if (controller.isLoading.value &&
            controller.cartItems.isEmpty) {
          return _shimmer();
        }

        if (controller.cartItems.isEmpty) {
          return _emptyCart();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
          child: Column(
            children: [

              /// ================= CART ITEMS =================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchCart,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: controller.cartItems
                        .map((item) => CartItemTile(
                              item: item,
                              controller: controller,
                            ))
                        .toList(),
                  ),
                ),
              ),

              const Divider(),

              Obx(() => _priceRow(
                    'Subtotal',
                    controller.subtotal.value,
                  )),

              Obx(() => controller.isDelivery.value
                  ? _priceRow(
                      'Delivery Fee',
                      controller.deliveryFee.value,
                    )
                  : const SizedBox.shrink()),

              Obx(() => _priceRow(
                    'Platform Fee',
                    controller.platformFee.value,
                  )),

              const Divider(),

              Obx(() => _priceRow(
                    'Total',
                    controller.totalAmount.value,
                    isBold: true,
                    big: true,
                  )),

              const SizedBox(height: 15),

              /// ================= DELIVERY / PICKUP TOGGLE =================
              Obx(() => Row(
                    children: [

                      /// DELIVERY
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.toggleDelivery(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: controller.isDelivery.value
                                  ? ColorConstants.success
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Delivery",
                                style: TextStyle(
                                  color: controller.isDelivery.value
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// SELF PICKUP
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.toggleDelivery(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: !controller.isDelivery.value
                                  ? ColorConstants.success
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Self Pickup",
                                style: TextStyle(
                                  color: !controller.isDelivery.value
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),

              const SizedBox(height: 10),

              /// ================= CHECKBOX =================
              Obx(() => Row(
                    children: [
                      Checkbox(
                        activeColor: ColorConstants.success,
                        value: controller.isReturnDoorstep.value,
                        onChanged: (val) {
                          controller.isReturnDoorstep.value = val ?? false;
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Please keep your items ready at the doorstep for inspection. Return will be done immediately at the doorstep.",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  )),

              const SizedBox(height: 10),

              /// ================= PAYMENT BUTTON =================
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.isReturnDoorstep.value
                                ? ColorConstants.success
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: controller.isReturnDoorstep.value
                          ? () {
                              Get.to(() =>
                                  const SelectLocationScreen());
                            }
                          : null,
                      child: const Text(
                        "Proceed to Payment",
                        style: TextStyle(
                            fontSize: 18, color: Colors.white),
                      ),
                    ),
                  )),
            ],
          ),
        );
      }),
    );
  }

  /// ================= PRICE ROW =================
  Widget _priceRow(
    String title,
    double value, {
    bool isBold = false,
    bool big = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: big ? 18 : 14,
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: big ? 20 : 14,
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SHIMMER =================
  Widget _shimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade200,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  /// ================= EMPTY CART =================
  Widget _emptyCart() {
    return Column(
      children: [
        const Spacer(),
        SizedBox(
          height: 220,
          child: Image.asset(ImageConstant.emptyCart),
        ),
        const SizedBox(height: 20),
        const Text(
          "Your Cart is Empty",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
              Get.offAll(() => const HomeView(),
                  binding: HomeBinding());
            },
            child: const Text(
              "Go back to home",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}