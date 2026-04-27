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

  Future<void> _handleAddSingleVariant({
    required String productId,
    required String varietyId,
  }) async {
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
    final productDescription = (product["description"] ?? "").toString().trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: hasMultipleOptions ? () => _openProductSheet(product) : null,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE4ECE8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF113B2C).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
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
                        top: Radius.circular(20),
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
                        top: Radius.circular(20),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
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
                    top: 12,
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
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18342B),
                            ),
                          ),
                        ],
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
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        hasMultipleOptions
                            ? "${varieties.length} options"
                            : "Quick add",
                        style: const TextStyle(
                          color: Color(0xFF17392D),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
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
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Obx(
                      () => _buildEmbeddedAction(
                        product: product,
                        productId: productId,
                        varietyId: varietyId,
                        firstVariety: firstVariety,
                        hasMultipleOptions: hasMultipleOptions,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF18342B),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (productDescription.isNotEmpty) ...[
                        Text(
                          productDescription,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: Color(0xFF6A8479),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        "₹$price",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Color(0xFF18342B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
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
                      if (hasCartItem) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hasMultipleOptions
                                    ? "$totalProductQuantity added"
                                    : "$quantity added",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (hasMultipleOptions) ...[
                        const SizedBox(height: 5),
                        Text(
                          "Tap card or + to open options",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmbeddedAction({
    required Map<String, dynamic> product,
    required String? productId,
    required String? varietyId,
    required Map<String, dynamic>? firstVariety,
    required bool hasMultipleOptions,
  }) {
    final productCartItems = productId != null
        ? cartController.getCartItemsForProduct(productId)
        : const <CartItem>[];
    final hasCartItem = productCartItems.isNotEmpty;
    final totalProductQuantity = productCartItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final inlineCartItem =
        !hasMultipleOptions && productId != null && varietyId != null
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
        height: 34,
        decoration: BoxDecoration(
          color: cartController.isUpdatingCart.value
              ? ColorConstants.primaryDark.withValues(alpha: 0.7)
              : ColorConstants.primaryDark,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _compactIconButton(
              icon: Icons.remove_rounded,
              onTap: cartController.isUpdatingCart.value
                  ? null
                  : () => cartController.decreaseQty(inlineCartItem),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                quantity.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _compactIconButton(
              icon: Icons.add_rounded,
              onTap: cartController.isUpdatingCart.value
                  ? null
                  : () => cartController.increaseQty(inlineCartItem),
            ),
          ],
        ),
      );
    }

    if (hasMultipleOptions) {
      return _floatingOptionButton(
        label: "${varietiesLabel(product)} options",
        onTap: () => _openProductSheet(product),
        badgeText: hasCartItem ? "$totalProductQuantity" : null,
      );
    }

    return _floatingOptionButton(
      label: _singleOptionLabel(firstVariety),
      onTap: isAddingToCart ||
              firstVariety == null ||
              productId == null ||
              varietyId == null
          ? null
          : () => _handleAddSingleVariant(
                productId: productId,
                varietyId: varietyId,
              ),
      isLoading: isAddingToCart,
    );
  }

  String varietiesLabel(Map<String, dynamic> product) {
    final varieties = product["varieties"] as List<dynamic>? ?? [];
    return varieties.length.toString();
  }

  String _singleOptionLabel(Map<String, dynamic>? firstVariety) {
    final name = firstVariety?["name"]?.toString().trim() ?? "";
    if (name.isEmpty) return "Add";
    return name;
  }

  Widget _compactIconButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 28,
        height: 34,
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _floatingOptionButton({
    required String label,
    required VoidCallback? onTap,
    bool isLoading = false,
    String? badgeText,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, maxWidth: 132),
              height: 36,
              padding: const EdgeInsets.only(left: 10, right: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ColorConstants.primaryDark,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17392D),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (badgeText != null)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: ColorConstants.primaryDark,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
