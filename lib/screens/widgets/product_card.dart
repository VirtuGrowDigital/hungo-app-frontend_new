import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../utils/ColorConstants.dart';
import 'product_bottom_sheet.dart';

class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;

  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 14,
        childAspectRatio: 0.54,
      ),
      itemCount: products.length,
      itemBuilder: (_, index) => ProductCard(product: products[index]),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late final CartController cartController;
  bool isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
  }

  void _openProductSheet(Map<String, dynamic> product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductBottomSheet(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product["images"] as List<dynamic>? ?? [];
    final image = images.isNotEmpty
        ? images.first.toString()
        : "https://via.placeholder.com/150";
    final name = (product["name"] ?? "No Name").toString();
    final varieties = product["varieties"] as List<dynamic>? ?? [];
    final firstVariety =
        varieties.isNotEmpty ? varieties.first as Map<String, dynamic> : null;
    final price = firstVariety?["price"] ?? 0;
    final isBestseller = product["isBestseller"] == true;
    final rating = (product["rating"] is num)
        ? (product["rating"] as num).toDouble()
        : 0.0;
    final productId = product["_id"]?.toString();
    final varietyId = firstVariety?["_id"]?.toString();
    final hasMultipleOptions = varieties.length > 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: hasMultipleOptions ? () => _openProductSheet(product) : null,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4ECE8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF113B2C).withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF5FAF7),
                          Color(0xFFE9F4EE),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1.08,
                        child: Image.network(
                          image,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            "assets/logo/hunzo_main_logo.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18342B).withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        hasMultipleOptions
                            ? "${varieties.length} options"
                            : "Quick add",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: ColorConstants.warning,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : "New",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18342B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isBestseller)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18342B),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "Popular",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF18342B),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "₹$price",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                                color: Color(0xFF18342B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hasMultipleOptions
                                    ? "Choose your option"
                                    : (firstVariety?["name"]?.toString() ??
                                        "Single option"),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasMultipleOptions) ...[
                          const SizedBox(height: 5),
                          Text(
                            "Tap card or button to open options",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() {
                        final productCartItems = productId != null
                            ? cartController.getCartItemsForProduct(productId)
                            : const <CartItem>[];
                        final hasCartItem = productCartItems.isNotEmpty;
                        final totalProductQuantity = productCartItems.fold<int>(
                          0,
                          (sum, item) => sum + item.quantity,
                        );
                        final inlineCartItem = !hasMultipleOptions &&
                                productId != null &&
                                varietyId != null
                            ? cartController.getCartItem(
                                productId: productId,
                                varietyId: varietyId,
                              )
                            : productCartItems.length == 1
                                ? productCartItems.first
                                : null;
                        final quantity = inlineCartItem?.quantity ?? 0;

                        if (inlineCartItem != null && quantity > 0) {
                          return Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: cartController.isUpdatingCart.value
                                  ? ColorConstants.orangeRed
                                      .withValues(alpha: 0.65)
                                  : ColorConstants.orangeRed,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: IconButton(
                                    onPressed:
                                        cartController.isUpdatingCart.value
                                            ? null
                                            : () => cartController
                                                .decreaseQty(inlineCartItem),
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    splashRadius: 18,
                                  ),
                                ),
                                Text(
                                  quantity.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Expanded(
                                  child: IconButton(
                                    onPressed:
                                        cartController.isUpdatingCart.value
                                            ? null
                                            : () => cartController
                                                .increaseQty(inlineCartItem),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    splashRadius: 18,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (hasMultipleOptions) {
                          return SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () => _openProductSheet(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasCartItem
                                    ? const Color(0xFF18342B)
                                    : ColorConstants.orangeRed,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: Text(
                                hasCartItem
                                    ? "View options • $totalProductQuantity in cart"
                                    : "Add",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: isAddingToCart ||
                                    firstVariety == null ||
                                    productId == null ||
                                    varietyId == null
                                ? null
                                : () async {
                                    setState(() => isAddingToCart = true);

                                    try {
                                      await cartController.addToCart(
                                        productId: productId,
                                        varietyId: varietyId,
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() => isAddingToCart = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: ColorConstants.orangeRed
                                  .withValues(alpha: 0.65),
                              backgroundColor: ColorConstants.orangeRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: isAddingToCart
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text("Add"),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
