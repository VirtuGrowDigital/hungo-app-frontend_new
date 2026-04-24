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

  @override
  void initState() {
    super.initState();
    cartController = Get.isRegistered<CartController>()
        ? Get.find<CartController>()
        : Get.put(CartController(), permanent: true);
    _pageController = PageController();

    if (images.length > 1) {
      Future.delayed(const Duration(seconds: 3), autoSlide);
    }
  }

  void autoSlide() {
    if (!mounted || images.length <= 1) return;

    currentImage = (currentImage + 1) % images.length;
    _pageController.animateToPage(
      currentImage,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );

    Future.delayed(const Duration(seconds: 3), autoSlide);
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
    final selectedVariety = sizes.isNotEmpty ? sizes[selectedSize] : null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildImageGallery(rating: rating, isBestseller: isBestseller),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF133629).withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
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
                            child: Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF18342B),
                                height: 1.15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F8F6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Starts at",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7A8D85),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "₹$startingPrice",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF18342B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.inventory_2_outlined,
                            label: selectedVariety?['name']?.toString() ??
                                "Multiple options",
                          ),
                          _InfoChip(
                            icon: Icons.currency_rupee_rounded,
                            label: selectedVariety?['price']?.toString() ?? "0",
                          ),
                          _InfoChip(
                            icon: Icons.shopping_bag_outlined,
                            label: sizes.isEmpty
                                ? "Unavailable"
                                : "${sizes.length} option${sizes.length == 1 ? '' : 's'}",
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        productDescription.isNotEmpty
                            ? productDescription
                            : "Product description will appear here once it is added from the admin panel.",
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Choose your option",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18342B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (sizes.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8F8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            "No sizes available for this product right now.",
                            style: TextStyle(fontSize: 14),
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
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F9F7),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border:
                                    Border.all(color: const Color(0xFFE1E8E3)),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: quantity > 1
                                        ? () => setState(() => quantity--)
                                        : null,
                                    icon: const Icon(
                                      Icons.remove_rounded,
                                      color: Color(0xFF18342B),
                                    ),
                                  ),
                                  Text(
                                    "$quantity",
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF18342B),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => quantity++),
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: Color(0xFF18342B),
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
                                  onPressed: isLoading ||
                                          selectedVariety == null
                                      ? null
                                      : () => addToCartApi(
                                            productId:
                                                product["_id"].toString(),
                                            varietyId: selectedVariety["_id"]
                                                .toString(),
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorConstants.orangeRed,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: ColorConstants
                                        .orangeRed
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
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
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
      height: 256,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8FCF9),
            Color(0xFFE6F1EB),
          ],
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
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
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: ColorConstants.warning,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    rating > 0 ? rating.toStringAsFixed(1) : "New",
                    style: const TextStyle(
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
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF18342B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  "Bestseller",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentImage == index ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentImage == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
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

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => setState(() => selectedSize = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCEEE9) : const Color(0xFFF7F8F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? ColorConstants.orangeRed : const Color(0xFFE1E8E3),
            width: isSelected ? 1.6 : 1,
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
                      color: Color(0xFF18342B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹$price",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isSelected ? ColorConstants.orangeRed : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? ColorConstants.orangeRed
                      : Colors.grey.shade400,
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

  Future<void> addToCartApi({
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
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF18342B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18342B),
            ),
          ),
        ],
      ),
    );
  }
}
