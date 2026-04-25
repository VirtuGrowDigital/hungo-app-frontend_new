import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hungzo_app/services/Api/api_constants.dart';
import 'package:hungzo_app/utils/snack_bar.dart';

import 'auth_controller.dart';

class CartController extends GetxController {
  static const String deliveryType = "DELIVERY";
  static const String selfPickupType = "SELF_PICKUP";

  /// ================= STATE =================

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUpdatingCart = false.obs;
  final RxString fulfillmentType = deliveryType.obs;
  final RxBool deliveryVerificationAccepted = false.obs;
  final Rxn<CartDeliveryAddress> selectedDeliveryAddress =
      Rxn<CartDeliveryAddress>();

  final RxDouble subtotal = 0.0.obs;
  final RxDouble deliveryFee = 0.0.obs;
  final RxDouble platformFee = 12.0.obs;
  final RxDouble totalAmount = 0.0.obs;

  final String cartUrl = "${ApiConstants.baseURL}cart";

  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  @override
  void onReady() {
    super.onReady();
    fetchCart();
  }

  bool get isSelfPickup => fulfillmentType.value == selfPickupType;

  int get totalCartItemCount =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);

  // ================= FETCH CART =================

  Future<void> fetchCart({String? type}) async {
    try {
      isLoading(true);

      if (type != null) {
        fulfillmentType.value = type;
      }

      final token = await secureStorage.read(key: 'accessToken');

      if (token == null || token.isEmpty) {
        debugPrint("Token missing");
        return;
      }

      final uri = Uri.parse(cartUrl).replace(
        queryParameters: {
          "fulfillmentType": fulfillmentType.value,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      debugPrint("statusCode = ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        subtotal.value = (data["subTotal"] ?? 0).toDouble();
        deliveryFee.value = (data["deliveryCharge"] ?? 0).toDouble();
        platformFee.value = (data["platformFee"] ?? 0).toDouble();
        totalAmount.value = (data["totalAmount"] ?? 0).toDouble();

        final List items = data["items"] ?? [];

        cartItems.value = items.map((e) => CartItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("fetchCart error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> setFulfillmentType(String type) async {
    if (fulfillmentType.value == type) return;
    await fetchCart(type: type);
  }

  void setDeliveryVerificationAccepted(bool accepted) {
    deliveryVerificationAccepted.value = accepted;
  }

  void setSelectedDeliveryAddress(CartDeliveryAddress? address) {
    selectedDeliveryAddress.value = address;
  }

  CartItem? getCartItem({
    required String productId,
    required String varietyId,
  }) {
    try {
      return cartItems.firstWhere(
        (item) => item.productId == productId && item.varietyId == varietyId,
      );
    } catch (_) {
      return null;
    }
  }

  int getCartQuantity({
    required String productId,
    required String varietyId,
  }) {
    return getCartItem(productId: productId, varietyId: varietyId)?.quantity ??
        0;
  }

  List<CartItem> getCartItemsForProduct(String productId) {
    return cartItems.where((item) => item.productId == productId).toList();
  }

  Future<bool> addToCart({
    required String productId,
    required String varietyId,
    int quantity = 1,
    bool showSuccessMessage = true,
  }) async {
    try {
      final token = await secureStorage.read(key: 'accessToken');

      if (token == null || token.isEmpty) {
        final didLogin = await Get.find<AuthController>().ensureAuthenticated(
          message: "Please log in to add items to your cart",
        );

        if (!didLogin) {
          return false;
        }
      }

      final refreshedToken = await secureStorage.read(key: 'accessToken');

      if (refreshedToken == null || refreshedToken.isEmpty) {
        CustomSnackBar("Login session not available", "E");
        return false;
      }

      final response = await http.post(
        Uri.parse("$cartUrl/add"),
        headers: {
          "Authorization": "Bearer $refreshedToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "productId": productId,
          "varietyId": varietyId,
          "quantity": quantity,
        }),
      );

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (showSuccessMessage) {
          CustomSnackBar("Item added to cart", "S");
        }

        await fetchCart();
        return true;
      }

      CustomSnackBar(data["message"]?.toString() ?? "Failed", "E");
      return false;
    } catch (e) {
      debugPrint("addToCart error: $e");
      CustomSnackBar(e.toString(), "E");
      return false;
    }
  }

  // ================= REMOVE ITEM =================

  Future<void> removeItem(CartItem item) async {
    try {
      isUpdatingCart(true);
      final token = await secureStorage.read(key: 'accessToken');

      if (token == null || token.isEmpty) {
        debugPrint("Token missing");
        return;
      }

      final response = await http.delete(
        Uri.parse("${ApiConstants.baseURL}cart/remove"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(
            {"productId": item.productId, "varietyId": item.varietyId}),
      );

      debugPrint("Remove API status: ${response.statusCode}");

      if (response.statusCode == 200) {
        await fetchCart();
      } else {
        debugPrint("Remove failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("removeItem error: $e");
    } finally {
      isUpdatingCart(false);
    }
  }

  // ================= INCREASE QUANTITY =================

  Future<void> increaseQty(CartItem item) async {
    await updateItemQuantity(item, item.quantity + 1);
  }

  // ================= DECREASE QUANTITY =================

  Future<void> decreaseQty(CartItem item) async {
    final updatedQuantity = item.quantity - 1;

    if (updatedQuantity < 1) {
      await removeItem(item);
      return;
    }

    await updateItemQuantity(item, updatedQuantity);
  }

  Future<void> updateItemQuantity(CartItem item, int quantity) async {
    try {
      isUpdatingCart(true);
      final token = await secureStorage.read(key: 'accessToken');

      if (token == null || token.isEmpty) {
        debugPrint("Token missing");
        return;
      }

      final response = await http.put(
        Uri.parse("${ApiConstants.baseURL}cart/quantity"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "productId": item.productId,
          "varietyId": item.varietyId,
          "quantity": quantity,
        }),
      );

      debugPrint("Update quantity API status: ${response.statusCode}");

      if (response.statusCode == 200) {
        await fetchCart();
      } else {
        debugPrint("Update quantity failed: ${response.body}");
      }
    } catch (e) {
      debugPrint("updateItemQuantity error: $e");
    } finally {
      isUpdatingCart(false);
    }
  }
}

////////////////////////////////////////////////////////////
/// MODEL
////////////////////////////////////////////////////////////

class CartItem {
  final String productId;
  final String? varietyId;
  final String varietyName;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    this.varietyId,
    required this.varietyName,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final variety = json['variety'];

    return CartItem(
      productId: json['productId'] ?? "",
      varietyId: variety?['id'],
      varietyName: variety?['name']?.toString() ?? '',
      name: json['productName'] ?? "",
      image: json['image'] ?? "",
      price: variety != null ? (variety['price'] as num).toDouble() : 0.0,
      quantity: json['quantity'] ?? 1,
    );
  }
}

class CartDeliveryAddress {
  final String? addressId;
  final String title;
  final String fullAddress;
  final String? receiverPhone;
  final double? latitude;
  final double? longitude;

  const CartDeliveryAddress({
    this.addressId,
    required this.title,
    required this.fullAddress,
    this.receiverPhone,
    this.latitude,
    this.longitude,
  });

  factory CartDeliveryAddress.fromJson(Map<String, dynamic> json) {
    return CartDeliveryAddress(
      addressId: json['addressId']?.toString(),
      title: json['title']?.toString() ?? 'Delivery address',
      fullAddress: json['fullAddress']?.toString() ?? '',
      receiverPhone: json['receiverPhone']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}
