import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/cart_controller.dart';
import '../../utils/ColorConstants.dart';

class ProductBottomSheet extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductBottomSheet({super.key, required this.product});

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  int selectedSize = 0;
  int quantity = 1;
  bool isLoading = false;
  bool isDescriptionExpanded = false;
  late final CartController cartController;
  late final PageController _pageController;
  int currentImage = 0;

  List<Map<String, dynamic>> get sizes {
    final varieties = widget.product['varieties'] as List<dynamic>?;
    if (varieties == null || varieties.isEmpty) {
      return [];
    }
    return varieties.cast<Map<String, dynamic>>();
  }

  List<String> get images {
    final imgs = widget.product['images'] as List<dynamic>?;
    if (imgs == null || imgs.isEmpty) {
      return ["https://via.placeholder.com/300"];
    }
    return imgs.map((image) => image.toString()).toList();
  }

  int get totalPrice {
    if (sizes.isEmpty) return 0;
    final price = sizes[selectedSize]['price'];
    if (price is int) return price * quantity;
    if (price is double) return price.round() * quantity;
    return int.tryParse(price.toString()) != null
        ? int.parse(price.toString()) * quantity
        : 0;
  }

  int get startingPrice {
    if (sizes.isEmpty) return 0;
    return sizes
        .map((item) => int.tryParse(item['price'].toString()) ?? 0)
        .reduce((a, b) => a < b ? a : b);
  }

  Map<String, dynamic>? get selectedVariety =>
      sizes.isNotEmpty ? sizes[selectedSize] : null;

  @override
  void initState() {
    super.initState();
    cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
    _pageController = PageController();

    if (images.length > 1) {
      Future.delayed(const Duration(seconds: 3), _autoSlide);
    }
  }

  void _autoSlide() {
    if (!mounted || images.length <= 1) return;

    currentImage = (currentImage + 1) % images.length;
    _pageController.animateToPage(
      currentImage,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(seconds: 3), _autoSlide);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final productName = (product["name"] ?? "Unknown product").toString();
    final productDescription = (product["description"] ?? "").toString().trim();
    final isBestseller = product["isBestseller"] == true;
    final rating = (product["rating"] is num)
        ? (product["rating"] as num).toDouble()
        : 0.0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6FBF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.65,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2DFD8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _buildImageGallery(
                        rating: rating,
                        isBestseller: isBestseller,
                      ),
                      const SizedBox(height: 16),
                      _surfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF17392D),
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _MetaChip(
                                            icon: Icons.category_outlined,
                                            label: selectedVariety?['name']
                                                    ?.toString() ??
                                                "Multiple options",
                                          ),
                                          _MetaChip(
                                            icon: Icons.shopping_bag_outlined,
                                            label:
                                                "${sizes.length} option${sizes.length == 1 ? '' : 's'}",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF7F1),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        "Starts at",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF5F7A6E),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "₹$startingPrice",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF17392D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ExpandableDescription(
                              text: productDescription.isNotEmpty
                                  ? productDescription
                                  : "Freshly prepared product details will appear here once they are updated in the catalog.",
                              expanded: isDescriptionExpanded,
                              onToggle: () => setState(
                                () => isDescriptionExpanded =
                                    !isDescriptionExpanded,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _surfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.widgets_outlined,
                                  size: 18,
                                  color: ColorConstants.primaryDark,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Available options",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF17392D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (sizes.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF6FAF7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD9E7E0),
                                  ),
                                ),
                                child: const Text(
                                  "No options are available for this product right now.",
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: Color(0xFF5F7A6E),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: sizes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) =>
                                    _buildVarietyTile(index),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FCFA),
                    border: Border(
                      top: BorderSide(color: Color(0xFFD9E7E0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFD9E7E0),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: quantity > 1
                                  ? () => setState(() => quantity--)
                                  : null,
                              icon: Icon(
                                Icons.remove_rounded,
                                color: quantity > 1
                                    ? const Color(0xFF17392D)
                                    : const Color(0xFFABC0B6),
                              ),
                            ),
                            Text(
                              "$quantity",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF17392D),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => quantity++),
                              icon: const Icon(
                                Icons.add_rounded,
                                color: Color(0xFF17392D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading || selectedVariety == null
                                ? null
                                : () => _addToCartApi(
                                      productId: product["_id"].toString(),
                                      varietyId:
                                          selectedVariety!["_id"].toString(),
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorConstants.primaryDark,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: ColorConstants
                                  .primaryDark
                                  .withValues(alpha: 0.55),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    "Add to cart  •  ₹$totalPrice",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageGallery({
    required double rating,
    required bool isBestseller,
  }) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7FCF9),
            Color(0xFFE5F1EB),
          ],
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => currentImage = index);
              },
              itemBuilder: (context, index) {
                return Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/logo/img.png',
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            child: _TopBadge(
              icon: Icons.star_rounded,
              text: rating > 0 ? rating.toStringAsFixed(1) : "New",
              light: true,
            ),
          ),
          if (isBestseller)
            const Positioned(
              top: 14,
              right: 14,
              child: _TopBadge(
                icon: Icons.local_fire_department_outlined,
                text: "Popular",
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentImage == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentImage == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVarietyTile(int index) {
    final isSelected = selectedSize == index;
    final label = sizes[index]['name']?.toString() ?? "Option ${index + 1}";
    final price = sizes[index]['price']?.toString() ?? "0";
    final isAvailable = sizes[index]['isAvailable'] != false;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isAvailable ? () => setState(() => selectedSize = index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEAF7F1) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? ColorConstants.primaryDark
                : const Color(0xFFDCE8E1),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17392D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "₹$price",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17392D),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFFEAF7F1)
                              : const Color(0xFFF3F5F4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isAvailable ? "Available" : "Unavailable",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isAvailable
                                ? ColorConstants.primaryDark
                                : const Color(0xFF92A59B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? ColorConstants.primaryDark
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? ColorConstants.primaryDark
                      : const Color(0xFFB7C9C0),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCartApi({
    required String productId,
    required String varietyId,
  }) async {
    setState(() => isLoading = true);

    try {
      final didAdd = await cartController.addToCart(
        productId: productId,
        varietyId: varietyId,
        quantity: quantity,
      );

      if (didAdd && mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Widget _surfaceCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE8E1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C2D).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE8E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF17392D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17392D),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool light;

  const _TopBadge({
    required this.icon,
    required this.text,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.92)
            : const Color(0xFF17392D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: light ? ColorConstants.warning : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: light ? const Color(0xFF17392D) : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableDescription({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: expanded ? null : 1,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Color(0xFF5D776D),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              expanded ? "Show less" : "Show more",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: ColorConstants.primaryDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
