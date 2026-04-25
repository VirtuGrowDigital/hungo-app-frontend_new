import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hungzo_app/screens/widgets/banner_card.dart';
import 'package:hungzo_app/screens/widgets/category_card.dart';
import 'package:hungzo_app/screens/widgets/filter_bar.dart';
import 'package:hungzo_app/screens/widgets/product_card.dart';
import 'package:hungzo_app/screens/widgets/search_bar.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/cart_controller.dart';
import '../controllers/home_controller.dart';
import '../utils/ColorConstants.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const double _bottomNavHeight = 70;

  double _cartBadgeLeft(double width, int itemCount) {
    final itemWidth = width / 4;
    final cartCenter = itemWidth * 1.5;
    final badgeWidth = itemCount > 99 ? 28.0 : 20.0;
    return cartCenter - 2 + (30 / 2) - (badgeWidth / 2);
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Scaffold(
      backgroundColor: ColorConstants.mintCream,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => controller.changeTab(0),
        child: const CircleAvatar(
          backgroundColor: Colors.white,
          backgroundImage: AssetImage("assets/logo/hunzo_main_logo.png"),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Obx(() => controller.screens[controller.bottomIndex.value]),
      bottomNavigationBar: Obx(() {
        final itemCount = cartController.cartItems.fold<int>(
          0,
          (sum, item) => sum + item.quantity,
        );

        return SizedBox(
          height: _bottomNavHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: AnimatedBottomNavigationBar(
                      icons: controller.iconList,
                      activeIndex: controller.bottomIndex.value,
                      gapLocation: GapLocation.none,
                      activeColor: ColorConstants.primary,
                      inactiveColor: Colors.grey,
                      iconSize: 30,
                      leftCornerRadius: 30,
                      rightCornerRadius: 30,
                      onTap: controller.changeTab,
                    ),
                  ),
                  if (itemCount > 0)
                    Positioned(
                      left: _cartBadgeLeft(constraints.maxWidth, itemCount),
                      top: 8,
                      child: IgnorePointer(
                        child: Container(
                          constraints: BoxConstraints(
                            minWidth: itemCount > 99 ? 28 : 20,
                            minHeight: 20,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            itemCount > 99 ? '99+' : '$itemCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: ColorConstants.screenBackgroundGradient2,
          ),
          child: CustomScrollView(
            slivers: [
              /// 🔥 FIXED HEADER
              SliverPersistentHeader(
                pinned: true,
                delegate: HomeHeaderDelegate(),
              ),

              /// 🔥 BODY CONTENT
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const BannerCard(),
                    const SizedBox(height: 18),

                    Obx(() {
                      if (controller.isSearching) {
                        return _sectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Search Results',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF17392D),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Showing results for "${controller.searchQuery.value.trim()}"',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${controller.products.length} items found',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstants.primaryDark,
                                ),
                              ),
                              if (controller.searchError.value.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  controller.searchError.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return const _SectionHeading(
                        title: "Shop by category",
                        subtitle:
                            "Browse curated collections and discover products faster.",
                      );
                    }),
                    const SizedBox(height: 14),

                    /// ---------- CATEGORY ----------
                    Obx(() {
                      if (controller.isSearching) {
                        return const SizedBox.shrink();
                      }

                      if (controller.isLoading.value &&
                          controller.products.isEmpty) {
                        return _categoryShimmer();
                      }

                      final cats = controller.categories;

                      return _sectionCard(
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        child: SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cats.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, index) {
                              final category = cats[index];

                              String imageUrl = '';
                              final products =
                                  category['products'] as List<dynamic>?;

                              if (products != null && products.isNotEmpty) {
                                final firstProduct =
                                    products.first as Map<String, dynamic>;
                                final images =
                                    firstProduct['images'] as List<dynamic>?;

                                if (images != null && images.isNotEmpty) {
                                  imageUrl = images.first.toString();
                                }
                              }

                              return GestureDetector(
                                onTap: () => controller.changeCategory(
                                  category["category"],
                                ),
                                child: CategoryCard(
                                  title: category["category"] ?? 'Unknown',
                                  subtitle: "${products?.length ?? 0} items",
                                  image: imageUrl.isNotEmpty
                                      ? imageUrl
                                      : 'assets/permission/location.png',
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 18),
                    Obx(() => controller.isSearching
                        ? const SizedBox.shrink()
                        : const _SectionHeading(
                            title: "Refine your picks",
                            subtitle:
                                "Sort and filter products to find the best match.",
                          )),
                    const SizedBox(height: 12),
                    Obx(() => controller.isSearching
                        ? const SizedBox.shrink()
                        : _sectionCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: FilterBar(),
                            ),
                          )),
                    const SizedBox(height: 18),
                    Obx(
                      () => _SectionHeading(
                        title: controller.isSearching
                            ? "Matching products"
                            : "Popular products",
                        subtitle: controller.isSearching
                            ? "A refined list based on your current search."
                            : "${controller.products.length} products ready to order",
                      ),
                    ),
                    const SizedBox(height: 14),

                    /// ---------- PRODUCTS ----------
                    Obx(() {
                      if ((controller.isLoading.value ||
                              controller.isSearchLoading.value) &&
                          controller.products.isEmpty) {
                        return _productGridShimmer();
                      }
                      final products = controller.products;

                      if (products.isEmpty) {
                        return _sectionCard(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                controller.isSearching
                                    ? "No matching products found"
                                    : "No products available",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return _sectionCard(
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                        child: ProductGrid(products: products),
                      );
                    }),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productGridShimmer() {
    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.66,
        ),
        itemCount: 6,
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade200,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryShimmer() {
    return _sectionCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) {
            return Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade200,
              child: Container(
                width: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2ECE6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF123C2D).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF17392D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 84;

  @override
  double get maxExtent => 84;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFCFE3D7),
            Color(0xFFEAF5EF),
          ],
        ),
      ),
      child: const SearchDishBar(),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}
