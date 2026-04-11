import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hungzo_app/services/Api/api_constants.dart';

class CartController extends GetxController {

  /// ================= STATE =================

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

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

  // ================= CALCULATE TOTAL =================

  void calculateTotals() {

    double sub = cartItems.fold(
      0,
          (sum, item) => sum + (item.price * item.quantity),
    );

    subtotal.value = sub;

    totalAmount.value =
        subtotal.value + deliveryFee.value + platformFee.value;
  }

  // ================= FETCH CART =================

  Future<void> fetchCart() async {

    try {

      isLoading(true);

      final token = await secureStorage.read(key: 'accessToken');

      if (token == null || token.isEmpty) {
        print("Token missing");
        return;
      }

      final response = await http.get(
        Uri.parse(cartUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      print("statusCode = ${response.statusCode}");

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        subtotal.value = (data["subTotal"] ?? 0).toDouble();
        deliveryFee.value = (data["deliveryCharge"] ?? 0).toDouble();
        platformFee.value = (data["platformFee"] ?? 0).toDouble();
        totalAmount.value = (data["totalAmount"] ?? 0).toDouble();

        final List items = data["items"] ?? [];

        cartItems.value =
            items.map((e) => CartItem.fromJson(e)).toList();

        calculateTotals();
      }

    } catch (e) {

      print("fetchCart error: $e");

    } finally {

      isLoading(false);

    }
  }

  // ================= REMOVE ITEM =================

  Future<void> removeItem(CartItem item) async {
    try {
      final token = await secureStorage.read(key: 'accessToken');

      if (token == null || token.isEmpty) {
        print("Token missing");
        return;
      }

      final response = await http.delete(
        Uri.parse("${ApiConstants.baseURL}cart/remove"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "productId": item.productId,
          "varietyId": item.varietyId
        }),
      );

      print("Remove API status: ${response.statusCode}");

      if (response.statusCode == 200) {
        cartItems.remove(item);
        cartItems.refresh();
        calculateTotals();
      } else {
        print("Remove failed: ${response.body}");
      }
    } catch (e) {
      print("removeItem error: $e");
    }
  }

  // ================= INCREASE QUANTITY =================

  void increaseQty(CartItem item) {

    item.quantity++;

    cartItems.refresh();

    calculateTotals();
  }

  // ================= DECREASE QUANTITY =================

  void decreaseQty(CartItem item) {

    item.quantity--;

    if (item.quantity < 1) {

      cartItems.remove(item);

    }

    cartItems.refresh();

    calculateTotals();
  }
}

////////////////////////////////////////////////////////////
/// MODEL
////////////////////////////////////////////////////////////

class CartItem {

  final String productId;
  final String? varietyId;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    this.varietyId,
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
      name: json['productName'] ?? "",
      image: json['image'] ?? "",
      price: variety != null
          ? (variety['price'] as num).toDouble()
          : 0.0,
      quantity: json['quantity'] ?? 1,
    );
  }
}