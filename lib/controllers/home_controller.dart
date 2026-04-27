import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../screens/cart_screen.dart';
import '../screens/home_view.dart';
import '../screens/notification_screen.dart';
import '../screens/account_settings_screen.dart';
import '../controllers/cart_controller.dart';
import '../services/Api/api_constants.dart';
import '../services/permissions/app_permission_service.dart';

class HomeController extends GetxController {
  /// Bottom navigation index
  final RxInt bottomIndex = 0.obs;
  RxBool isLoading = true.obs;

  /// ================= FILTER STATE =================

  final RxnInt sortIndex = RxnInt(); // nullable
  final RxnInt priceRangeIndex = RxnInt();
  final RxBool ratingFilter = false.obs;
  final RxBool inStockOnly = false.obs;
  final RxBool isSearchLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString searchError = ''.obs;
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  /// ================= BANNERS =================
  final String bannerApiUrl = "${ApiConstants.baseURL}banners";
  final String searchApiUrl = "${ApiConstants.baseURL}products/search";

  final RxList<String> bannerImages = <String>[].obs;

  /// original products (backup)
  List<Map<String, dynamic>> originalProducts = [];
  List<Map<String, dynamic>> _sourceProducts = [];

  static const List<String> sortOptions = [
    "Recommended",
    "Price: Low to High",
    "Price: High to Low",
    "Top Rated",
    "Name: A to Z",
  ];

  static const List<String> priceRangeOptions = [
    "Under ₹100",
    "₹100 - ₹249",
    "₹250 - ₹499",
    "₹500 & above",
  ];

  /// Bottom navigation icons
  final List<IconData> iconList = const [
    Icons.home,
    Icons.shopping_cart_outlined,
    Icons.notifications_none,
    Icons.person_outline,
  ];

  /// Screens (kept alive by AnimatedBottomNavigationBar)
  final List<Widget> screens = [
    HomeScreen(),
    CartScreen(),
    NotificationScreen(),
    AccountSettingsScreen(),
  ];

  /// ================= API =================
  final String apiUrl = "${ApiConstants.baseURL}categories/menu";
  final RxList<Map<String, dynamic>> categories = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[].obs;
  final RxString selectedCategory = "".obs;
  final RxInt contentViewVersion = 0.obs;

  @override
  void onInit() {
    super.onInit();

    fetchCategories();
    fetchBanners(); // 🔥 ADD THIS

    /// ✅ Ensure CartController exists once
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }

  String get selectedSortLabel =>
      sortIndex.value == null ? "Sort" : sortOptions[sortIndex.value!];

  String get selectedPriceRangeLabel => priceRangeIndex.value == null
      ? "Price"
      : priceRangeOptions[priceRangeIndex.value!];

  bool get hasActiveFilters =>
      sortIndex.value != null ||
      priceRangeIndex.value != null ||
      ratingFilter.value ||
      inStockOnly.value;

  int get activeFilterCount {
    var count = 0;
    if (sortIndex.value != null) count++;
    if (priceRangeIndex.value != null) count++;
    if (ratingFilter.value) count++;
    if (inStockOnly.value) count++;
    return count;
  }

  String normalizeCategoryName(String? value) =>
      value?.trim().toLowerCase() ?? '';

  void updateFilterState({
    int? sort,
    bool resetSort = false,
    int? priceRange,
    bool resetPriceRange = false,
    bool? rating,
    bool? stockOnly,
  }) {
    sortIndex.value = resetSort ? null : sort ?? sortIndex.value;
    priceRangeIndex.value =
        resetPriceRange ? null : priceRange ?? priceRangeIndex.value;
    if (rating != null) ratingFilter.value = rating;
    if (stockOnly != null) inStockOnly.value = stockOnly;
    applyFilters();
  }

  void setSortIndex(int? value) => updateFilterState(
        sort: value,
        resetSort: value == null,
      );

  void setPriceRangeIndex(int? value) => updateFilterState(
        priceRange: value,
        resetPriceRange: value == null,
      );

  void toggleRatingFilter() => updateFilterState(rating: !ratingFilter.value);

  void toggleInStockOnly() => updateFilterState(stockOnly: !inStockOnly.value);

  void applyFilters() {
    List<Map<String, dynamic>> filtered = [..._sourceProducts];

    if (priceRangeIndex.value != null) {
      filtered = filtered
          .where(
              (product) => _matchesPriceRange(product, priceRangeIndex.value!))
          .toList();
    }

    if (ratingFilter.value) {
      filtered =
          filtered.where((product) => _productRating(product) >= 4).toList();
    }

    if (inStockOnly.value) {
      filtered =
          filtered.where((product) => _isProductAvailable(product)).toList();
    }

    if (sortIndex.value != null) {
      filtered.sort((a, b) {
        if (sortIndex.value == 1) {
          return _productPrice(a).compareTo(_productPrice(b));
        } else if (sortIndex.value == 2) {
          return _productPrice(b).compareTo(_productPrice(a));
        } else if (sortIndex.value == 3) {
          return _productRating(b).compareTo(_productRating(a));
        } else if (sortIndex.value == 4) {
          return _productName(a).compareTo(_productName(b));
        }

        return 0;
      });
    }

    products.assignAll(filtered);
  }

  /// ================= CATEGORY API =================
  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["success"] == true) {
          categories.assignAll(
            List<Map<String, dynamic>>.from(data["menu"]),
          );

          if (categories.isNotEmpty) {
            selectedCategory.value =
                categories.first["category"]?.toString().trim() ?? '';
            _setSourceProducts(
              List<Map<String, dynamic>>.from(categories.first["products"]),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("API ERROR: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    sortIndex.value = null;
    priceRangeIndex.value = null;
    ratingFilter.value = false;
    inStockOnly.value = false;
    applyFilters();
  }

  /// ================= CATEGORY CHANGE =================
  void changeCategory(String categoryName) {
    final normalizedCategoryName = categoryName.trim();
    if (normalizedCategoryName.isEmpty) return;
    if (normalizeCategoryName(selectedCategory.value) ==
        normalizeCategoryName(normalizedCategoryName)) {
      return;
    }

    final categoryIndex = categories.indexWhere(
      (category) =>
          normalizeCategoryName(category["category"]?.toString()) ==
          normalizeCategoryName(normalizedCategoryName),
    );

    if (categoryIndex == -1) return;

    final selectedCategoryData = categories[categoryIndex];
    selectedCategory.value =
        selectedCategoryData["category"]?.toString().trim() ?? '';
    selectedCategory.refresh();

    Future.microtask(() {
      if (isSearching) {
        clearSearch();
        return;
      }

      _setSourceProducts(
        List<Map<String, dynamic>>.from(selectedCategoryData["products"]),
      );
      contentViewVersion.value++;
    });
  }

  bool get isSearching => searchQuery.value.trim().isNotEmpty;

  void onSearchChanged(String value) {
    final normalizedValue = value.trimLeft();

    if (normalizedValue != value) {
      searchTextController.value = TextEditingValue(
        text: normalizedValue,
        selection: TextSelection.collapsed(offset: normalizedValue.length),
      );
    }

    searchQuery.value = normalizedValue;
    searchError.value = '';
    _searchDebounce?.cancel();

    final trimmedQuery = normalizedValue.trim();

    if (trimmedQuery.isEmpty) {
      isSearchLoading.value = false;
      _restoreSelectedCategoryProducts();
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => searchProducts(trimmedQuery),
    );
  }

  Future<void> searchProducts(String query) async {
    final activeRequestId = ++_searchRequestId;

    try {
      isSearchLoading.value = true;
      searchError.value = '';

      final uri = Uri.parse(searchApiUrl).replace(queryParameters: {
        'q': query,
        'limit': '20',
      });

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (activeRequestId != _searchRequestId ||
            searchQuery.value.trim() != query.trim()) {
          return;
        }

        if (data['success'] == true) {
          _setSourceProducts(
            List<Map<String, dynamic>>.from(data['products'] ?? []),
          );
          return;
        }

        searchError.value = data['message']?.toString() ?? 'Search failed';
      } else {
        searchError.value = 'Unable to search right now';
      }
    } catch (e) {
      debugPrint("SEARCH API ERROR: $e");
      searchError.value = 'Unable to search right now';
    } finally {
      isSearchLoading.value = false;
    }
  }

  void clearSearch() {
    _searchDebounce?.cancel();
    _searchRequestId++;
    searchTextController.clear();
    searchQuery.value = '';
    searchError.value = '';
    isSearchLoading.value = false;
    _restoreSelectedCategoryProducts();
    searchFocusNode.unfocus();
    contentViewVersion.value++;
  }

  void _restoreSelectedCategoryProducts() {
    if (selectedCategory.value.isEmpty) {
      _setSourceProducts(originalProducts);
      return;
    }

    final category = categories.firstWhere(
      (c) =>
          normalizeCategoryName(c["category"]?.toString()) ==
          normalizeCategoryName(selectedCategory.value),
      orElse: () => {},
    );

    if (category.isNotEmpty) {
      _setSourceProducts(List<Map<String, dynamic>>.from(category["products"]));
      return;
    }

    _setSourceProducts(originalProducts);
  }

  /// ================= TAB CHANGE (🔥 FIX HERE) =================
  Future<void> changeTab(int index) async {
    if (index == 2 && Get.context != null) {
      await AppPermissionService.ensureNotificationAccess(Get.context!);
    }

    bottomIndex.value = index;

    /// 🔥 WHEN CART TAB IS OPENED
    if (index == 1) {
      Get.find<CartController>().fetchCart();
    }
  }

  /// ================= BANNER API =================
  Future<void> fetchBanners() async {
    try {
      final response = await http.get(Uri.parse(bannerApiUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          final banners = List<Map<String, dynamic>>.from(data["banners"]);

          List<String> allImages = [];

          for (var banner in banners) {
            final images = List<String>.from(banner["images"]);
            allImages.addAll(images);
          }

          bannerImages.assignAll(allImages);
        }
      }
    } catch (e) {
      debugPrint("Banner API ERROR: $e");
    }
  }

  void _setSourceProducts(List<Map<String, dynamic>> source) {
    originalProducts = List<Map<String, dynamic>>.from(source);
    _sourceProducts = List<Map<String, dynamic>>.from(source);
    applyFilters();
    contentViewVersion.value++;
  }

  double _productPrice(Map<String, dynamic> product) {
    final varieties = product["varieties"] as List<dynamic>? ?? [];
    if (varieties.isNotEmpty) {
      final first = varieties.first as Map<String, dynamic>;
      final rawPrice = first["price"];
      if (rawPrice is num) return rawPrice.toDouble();
      return double.tryParse(rawPrice?.toString() ?? "0") ?? 0;
    }

    final rawPrice = product["price"];
    if (rawPrice is num) return rawPrice.toDouble();
    return double.tryParse(rawPrice?.toString() ?? "0") ?? 0;
  }

  double _productRating(Map<String, dynamic> product) {
    final rawRating = product["rating"];
    if (rawRating is num) return rawRating.toDouble();
    return double.tryParse(rawRating?.toString() ?? "0") ?? 0;
  }

  String _productName(Map<String, dynamic> product) =>
      (product["name"] ?? product["title"] ?? "").toString().toLowerCase();

  bool _isProductAvailable(Map<String, dynamic> product) {
    final varieties = product["varieties"] as List<dynamic>? ?? [];
    if (varieties.isEmpty) return true;

    return varieties.any((variety) {
      if (variety is! Map<String, dynamic>) return false;
      return variety["isAvailable"] != false;
    });
  }

  bool _matchesPriceRange(Map<String, dynamic> product, int rangeIndex) {
    final price = _productPrice(product);

    switch (rangeIndex) {
      case 0:
        return price < 100;
      case 1:
        return price >= 100 && price < 250;
      case 2:
        return price >= 250 && price < 500;
      case 3:
        return price >= 500;
      default:
        return true;
    }
  }
}
