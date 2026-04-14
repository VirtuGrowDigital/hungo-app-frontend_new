import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hungzo_app/model/cart_item.dart';
import 'package:hungzo_app/services/Api/api_constants.dart';

class CartController extends GetxController {

  /// ================= STATE =================

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

  final RxBool isDelivery = true.obs;
  final RxBool isReturnDoorstep = false.obs;

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

  /// ================= DELIVERY TOGGLE =================

  void toggleDelivery(bool value) {
    isDelivery.value = value;

    deliveryFee.value = isDelivery.value ? 40.0 : 0.0;

    calculateTotals();
  }

  /// ================= TOTAL CALCULATION =================

  void calculateTotals() {
    double sub = cartItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    subtotal.value = sub;

    totalAmount.value =
        subtotal.value + deliveryFee.value + platformFee.value;
  }

  /// ================= FETCH CART =================

  Future<void> fetchCart() async {
    try {
      isLoading(true);

      final token = await secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) return;

      final response = await http.get(
        Uri.parse(cartUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List items = data["items"] ?? [];

        cartItems.value =
            items.map((e) => CartItem.fromJson(e)).toList();

        platformFee.value = (data["platformFee"] ?? 12).toDouble();

        deliveryFee.value = isDelivery.value ? 40.0 : 0.0;

        calculateTotals();
      }
    } catch (e) {
      print("fetchCart error: $e");
    } finally {
      isLoading(false);
    }
  }

  /// ================= REMOVE ITEM =================

  Future<void> removeItem(CartItem item) async {
    try {
      final token = await secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) return;

      final Map<String, dynamic> body = {
        "productId": item.productId,
      };

      if (item.varietyId != null && item.varietyId!.isNotEmpty) {
        body["varietyId"] = item.varietyId;
      }

      final response = await http.delete(
        Uri.parse("${ApiConstants.baseURL}cart/remove"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        cartItems.remove(item);
        calculateTotals();
      }
    } catch (e) {
      print("removeItem error: $e");
    }
  }

  /// ================= QUANTITY INCREASE =================

  void increaseQty(CartItem item) {
    item.quantity++;
    cartItems.refresh();
    calculateTotals();
  }

  /// ================= QUANTITY DECREASE =================

  void decreaseQty(CartItem item) {
    item.quantity--;

    if (item.quantity < 1) {
      cartItems.remove(item);
    }

    cartItems.refresh();
    calculateTotals();
  }
}