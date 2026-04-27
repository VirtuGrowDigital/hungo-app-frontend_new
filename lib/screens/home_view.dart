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
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/wallet_controller.dart';
import '../utils/ColorConstants.dart';
import 'wallet_screen.dart';

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
        backgroundColor: ColorConstants.mintCream,
        body: Container(
          decoration: const BoxDecoration(
            gradient: ColorConstants.screenBackgroundGradient2,
          ),
          child: NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverPersistentHeader(
                pinned: true,
                delegate: HomeHeaderDelegate(),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: BannerCard(),
                ),
              ),
            ],
            body: const _MarketplaceSection(),
          ),
        ),
      ),
    );
  }
}

class _MarketplaceSection extends StatefulWidget {
  const _MarketplaceSection();

  @override
  State<_MarketplaceSection> createState() => _MarketplaceSectionState();
}

class _MarketplaceSectionState extends State<_MarketplaceSection> {
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Container(
      color: const Color(0xFFF4FBF7),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF8FCFA),
              border: Border(
                top: BorderSide(color: Color(0xFFD9E7E0)),
                bottom: BorderSide(color: Color(0xFFD9E7E0)),
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: FilterBar(),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 104,
                    child: Obx(() {
                      if (controller.isLoading.value &&
                          controller.categories.isEmpty) {
                        return _CategoryRailShimmer(
                          controller: _categoryScrollController,
                        );
                      }

                      return _CategoryRail(
                        scrollController: _categoryScrollController,
                      );
                    }),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: Color(0xFFD9E7E0),
                  ),
                  Expanded(
                    child: Obx(() {
                      if ((controller.isLoading.value ||
                              controller.isSearchLoading.value) &&
                          controller.products.isEmpty) {
                        return const _ProductPaneShimmer();
                      }

                      return _ProductPane(
                        key: ValueKey(
                          "${controller.selectedCategory.value}-${controller.searchQuery.value}-${controller.contentViewVersion.value}",
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends GetView<HomeController> {
  final ScrollController scrollController;

  const _CategoryRail({required this.scrollController});

  void _scrollToCategory(int index) {
    if (!scrollController.hasClients) return;

    const itemExtent = 122.0;
    final targetOffset = (index * itemExtent).toDouble();
    final maxScrollExtent = scrollController.position.maxScrollExtent;

    scrollController.animateTo(
      targetOffset.clamp(0.0, maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5FBF8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Shop by",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6A8579),
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                "Categories",
                textAlign: TextAlign.left,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17392D),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(
            () => ScrollConfiguration(
              behavior: const _NoScrollbarScrollBehavior(),
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
                itemCount: controller.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final category = controller.categories[index];
                  final categoryName =
                      category["category"]?.toString().trim() ?? "Unknown";
                  final products = category['products'] as List<dynamic>? ?? [];
                  var imageUrl = '';

                  if (products.isNotEmpty) {
                    final firstProduct = products.first as Map<String, dynamic>;
                    final images =
                        firstProduct['images'] as List<dynamic>? ?? [];
                    if (images.isNotEmpty) {
                      imageUrl = images.first.toString();
                    }
                  }

                  return CategoryCard(
                    key: ValueKey(categoryName),
                    title: categoryName,
                    subtitle: "${products.length} items",
                    image: imageUrl.isNotEmpty
                        ? imageUrl
                        : 'assets/permission/location.png',
                    isSelected: controller.normalizeCategoryName(
                          controller.selectedCategory.value,
                        ) ==
                        controller.normalizeCategoryName(categoryName),
                    onTap: () {
                      controller.changeCategory(categoryName);
                      _scrollToCategory(index);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoScrollbarScrollBehavior extends MaterialScrollBehavior {
  const _NoScrollbarScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _ProductPane extends GetView<HomeController> {
  const _ProductPane({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryController = PrimaryScrollController.of(context);
    final products = controller.products;

    return CustomScrollView(
      controller: primaryController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: _ProductPaneHeader(controller: controller),
          ),
        ),
        if (controller.searchError.value.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD4D4)),
                ),
                child: Text(
                  controller.searchError.value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC23C3C),
                  ),
                ),
              ),
            ),
          ),
        if (products.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.search_off_rounded,
                        size: 34,
                        color: ColorConstants.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      controller.isSearching
                          ? "No products matched your search"
                          : "No products available right now",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17392D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Try another category or reset the filters to see more items.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: Color(0xFF678277),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, index) => ProductCard(product: products[index]),
                childCount: products.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.56,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductPaneHeader extends StatelessWidget {
  final HomeController controller;

  const _ProductPaneHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isSearching = controller.isSearching;
    final title = isSearching
        ? 'Results for "${controller.searchQuery.value.trim()}"'
        : controller.selectedCategory.value.isNotEmpty
            ? controller.selectedCategory.value
            : "All products";
    final subtitle = isSearching
        ? "${controller.products.length} matching products"
        : "${controller.products.length} products available";

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF4FCEB),
            Color(0xFFEAF7F1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E6DD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF17392D),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D776D),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isSearching)
            TextButton(
              onPressed: controller.clearSearch,
              style: TextButton.styleFrom(
                foregroundColor: ColorConstants.primaryDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text(
                "Clear",
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          else if (controller.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "${controller.activeFilterCount} active",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17392D),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryRailShimmer extends StatelessWidget {
  final ScrollController controller;

  const _CategoryRailShimmer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      radius: const Radius.circular(999),
      child: ListView.separated(
        controller: controller,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade200,
            child: Container(
              height: 106,
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
}

class _ProductPaneShimmer extends StatelessWidget {
  const _ProductPaneShimmer();

  @override
  Widget build(BuildContext context) {
    final primaryController = PrimaryScrollController.of(context);

    return CustomScrollView(
      controller: primaryController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade200,
              child: Container(
                height: 92,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, __) => Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade200,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.56,
            ),
          ),
        ),
      ],
    );
  }
}

class HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 138;

  @override
  double get maxExtent => 138;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
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
      child: const Column(
        children: [
          _HungzoHeaderBar(),
          SizedBox(height: 10),
          SearchDishBar(),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class _HungzoHeaderBar extends StatelessWidget {
  const _HungzoHeaderBar();

  String _formatBalance(double value) => "₹${value.toStringAsFixed(0)}";

  Future<void> _openWallet() async {
    final authController = Get.find<AuthController>();
    final didLogin = await authController.ensureAuthenticated(
      title: 'Login to view wallet',
      message: 'Please log in to check your wallet balance and transactions.',
    );

    if (!didLogin) return;

    final walletController = Get.find<WalletController>();
    await walletController.fetchWallet();
    Get.to(() => WalletScreen());
  }

  @override
  Widget build(BuildContext context) {
    final walletController = Get.find<WalletController>();
    final authController = Get.find<AuthController>();

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Hungzo",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF17392D),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(() {
            final isLoggedIn = authController.isLoggedIn.value;
            final balance = walletController.wallet.value?.balance ?? 0.0;
            final label = isLoggedIn ? _formatBalance(balance) : "Login";

            return Material(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                onTap: _openWallet,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD6E6DD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 19,
                        color: ColorConstants.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17392D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
