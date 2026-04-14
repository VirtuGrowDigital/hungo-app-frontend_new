// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:hungzo_app/data/models/HomeModel/home_model.dart';
// import 'package:hungzo_app/services/Api/api_constants.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// class OrderController extends GetxController {
//   final FlutterSecureStorage _storage = const FlutterSecureStorage();

//   Razorpay? _razorpay;

//   final RxBool isLoading = false.obs;
//   final RxBool paymentCompleted = false.obs;

//   String? _razorpayOrderId;

//   @override
//   void onReady() {
//     super.onReady();

//     _razorpay = Razorpay();
//     _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

//     debugPrint("✅ Razorpay initialized in onReady()");
//   }

//   @override
//   void onClose() {
//     _razorpay?.clear();
//     super.onClose();
//   }

//   // ================= PLACE ORDER =================
//   Future<void> placeOrder({
//     required String shippingAddress,
//     required String paymentMethod,
//   }) async {
//     isLoading.value = true;
//     paymentCompleted.value = false;

//     const String url = "${ApiConstants.baseURL}orders/place";

//     try {
//       final token = await _storage.read(key: 'accessToken');
//       print("token $token");
//       if (token == null) {
//         debugPrint("❌ Access token not found");
//         isLoading.value = false;
//         return;
//       }
//       print("Address $shippingAddress,paymentMethod $paymentMethod, Bearer $token");
//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "shippingAddress": shippingAddress,
//           "paymentMethod": paymentMethod,
//           "location" : {
//             "lat" : 0.00,
//             "lng" : 0.00
//           }
//         }),
//       );

//       final data = jsonDecode(response.body) as Map<String, dynamic>;
// print("Payment Data $data");
//       if (paymentMethod == "ONLINE" && data["success"] == true) {
//         if (data['type'] == "WALLET") {
//           isLoading.value = false;
//           paymentCompleted.value = true;
//         }
//         else{
//         _razorpayOrderId = data["razorpayOrderId"].toString();

//         debugPrint("📦 Razorpay Order ID: $_razorpayOrderId");

//         // 🔥 Direct open without postFrameCallback
//         _openRazorpay(
//           key: data["key"].toString(),
//           amount: int.parse(data["amount"].toString()),
//           razorpayOrderId: _razorpayOrderId!,
//         );
//       }
//       } else if (paymentMethod == "COD" && data["success"] == true) {
//         isLoading.value = false;
//         paymentCompleted.value = true;
//       } else {
//         isLoading.value = false;
//         Get.snackbar("Error", "Failed to place order");
//       }
//     } catch (e) {
//       debugPrint("❌ placeOrder error: $e");
//       isLoading.value = false;
//       Get.snackbar("Error", "Failed to place order: $e");
//     }
//   }

//   // ================= OPEN RAZORPAY =================
//   void _openRazorpay({
//     required String key,
//     required int amount,
//     required String razorpayOrderId,
//   }) {
//     if (_razorpay == null) {
//       debugPrint("❌ Razorpay not initialized");
//       isLoading.value = false;
//       return;
//     }

//     final options = {
//       'key': key,
//       'amount': amount, // Amount should be in paise (already from backend)
//       'order_id': razorpayOrderId,
//       'name': 'Hungzo Foods',
//       'description': 'Order Payment',
//       'image': 'https://dhafoods.com/assets/Chef-D2QYyU6P.png',
//       'theme': {'color': '#16AB88'},
//     };

//     debugPrint("🚀 Opening Razorpay");
//     debugPrint("Order ID: $razorpayOrderId");
//     debugPrint("Amount: $amount");

//     try {
//       _razorpay!.open(options);
//     } catch (e) {
//       debugPrint("❌ Error opening Razorpay: $e");
//       isLoading.value = false;
//       Get.snackbar("Error", "Failed to open payment gateway");
//     }
//   }

//   // ================= PAYMENT SUCCESS =================
//   Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
//     debugPrint("✅ PAYMENT SUCCESS CALLBACK CALLED");
//     debugPrint("Payment ID: ${response.paymentId}");
//     debugPrint("Order ID: ${response.orderId}");
//     debugPrint("Signature: ${response.signature}");

//     if (_razorpayOrderId == null) {
//       debugPrint("❌ Razorpay Order ID is null");
//       isLoading.value = false;
//       return;
//     }

//     // Show loading dialog
//     Get.dialog(
//       const Center(
//         child: Card(
//           child: Padding(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text("Verifying payment..."),
//               ],
//             ),
//           ),
//         ),
//       ),
//       barrierDismissible: false,
//     );

//     await verifyPayment(
//       razorpayOrderId: _razorpayOrderId!,
//       razorpayPaymentId: response.paymentId!,
//       razorpaySignature: response.signature!,
//     );
//   }

//   // ================= VERIFY PAYMENT =================
//   Future<void> verifyPayment({
//     required String razorpayOrderId,
//     required String razorpayPaymentId,
//     required String razorpaySignature,
//   }) async {
//     const String url = "${ApiConstants.baseURL}orders/verify-payment";

//     try {
//       final token = await _storage.read(key: 'accessToken');
//       if (token == null) {
//         debugPrint("❌ Access token not found");
//         Get.back(); // Close loading dialog
//         isLoading.value = false;
//         return;
//       }

//       debugPrint("🔍 Verifying payment...");

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "razorpay_order_id": razorpayOrderId,
//           "razorpay_payment_id": razorpayPaymentId,
//           "razorpay_signature": razorpaySignature,
//         }),
//       );

//       final data = jsonDecode(response.body) as Map<String, dynamic>;

//       debugPrint("Verification response: $data");

//       Get.back(); // Close loading dialog

//       if (response.statusCode == 200 && data["success"] == true) {
//         debugPrint("✅ Payment verified successfully");
//         isLoading.value = false;
//         paymentCompleted.value = true;
//       } else {
//         debugPrint("❌ Payment verification failed");
//         isLoading.value = false;
//         Get.snackbar(
//           "Error",
//           data["message"] ?? "Payment verification failed",
//           snackPosition: SnackPosition.BOTTOM,
//         );
//       }
//     } catch (e) {
//       debugPrint("❌ verifyPayment error: $e");
//       Get.back(); // Close loading dialog
//       isLoading.value = false;
//       Get.snackbar(
//         "Error",
//         "Failed to verify payment: $e",
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }

//   // ================= PAYMENT ERROR =================
//   void _handlePaymentError(PaymentFailureResponse response) {
//     debugPrint("❌ PAYMENT FAILED");
//     debugPrint("Error code: ${response.code}");
//     debugPrint("Error message: ${response.message}");

//     isLoading.value = false;

//     Get.snackbar(
//       "Payment Failed",
//       response.message ?? "Unknown error occurred",
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//     );
//   }

//   // ================= EXTERNAL WALLET =================
//   void _handleExternalWallet(ExternalWalletResponse response) {
//     debugPrint("💰 External wallet selected: ${response.walletName}");

//     isLoading.value = false;

//     Get.snackbar(
//       "Wallet",
//       response.walletName ?? "External wallet selected",
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }
// }









// class PanValidationScreen extends StatefulWidget {
//   const PanValidationScreen({super.key});
//
//   @override
//   State<PanValidationScreen> createState() => _PanValidationScreenState();
// }
//
// class _PanValidationScreenState extends State<PanValidationScreen> {
//   final TextEditingController panValidation = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool isValidPan(String pan){
//     final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}');
//     return panRegex.hasMatch(pan);
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
// appBar: AppBar(title: Text("PAN Card Validation"),),
//       body: Padding(
//           padding: EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 TextFormField(
//                   maxLength: 10,
//                   controller: panValidation,
//                   textCapitalization: TextCapitalization.characters,
//                   decoration: InputDecoration(
//                     labelText: "Enter Pan Car Number",
//
//                     border: OutlineInputBorder()
//                   ),
//                   validator: (value){
//                     if(value == null ||value.isEmpty){
//                       return "PAN Card is required";
//                     }else if(!isValidPan(value)){
//                       return "Enter a valid PAN number";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 50,),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(onPressed: () {
//                     if(_formKey.currentState!.validate()){
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text("PAN Card is Valid"))
//                       );
//                     }
//                   }, child: Text("Validate PAN")),
//                 )
//               ],
//             )),
//       ),
//     );
//   }
// }





import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hungzo_app/services/Api/api_constants.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class OrderController extends GetxController {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Razorpay? _razorpay;

  final RxBool isLoading = false.obs;
  final RxBool paymentCompleted = false.obs;

  String? _razorpayOrderId;
  String? _orderId;

  @override
  void onReady() {
    super.onReady();

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    debugPrint("✅ Razorpay initialized");
  }

  @override
  void onClose() {
    _razorpay?.clear();
    super.onClose();
  }

  // ================= PLACE ORDER =================
  Future<void> placeOrder({
    required String shippingAddress,
    required String paymentMethod,
  }) async {
    isLoading.value = true;
    paymentCompleted.value = false;

    const String url = "${ApiConstants.baseURL}orders/place";

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        isLoading.value = false;
        return;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "shippingAddress": shippingAddress,
          "paymentMethod": paymentMethod,
          "location": {
            "lat": 26.00,
            "lng": 24.00
          }
        }),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {

        // 🟢 WALLET
        if (data['type'] == "WALLET") {
          isLoading.value = false;
          paymentCompleted.value = true;
          return;
        }

        // 🔵 COD
        if (data['type'] == "COD") {
          isLoading.value = false;
          paymentCompleted.value = true;
          return;
        }

        // 🟡 ONLINE
        if (data['type'] == "ONLINE") {
          _razorpayOrderId = data["razorpayOrderId"];
          _orderId = data["orderId"];

          _openRazorpay(
            key: data["key"],
            amount: int.parse(data["amount"].toString()),
            razorpayOrderId: _razorpayOrderId!,
          );
        }

      } else {
        isLoading.value = false;
        Get.snackbar("Error", "Failed to place order");
      }

    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed: $e");
    }
  }

  // ================= OPEN RAZORPAY =================
  void _openRazorpay({
    required String key,
    required int amount,
    required String razorpayOrderId,
  }) {
    final options = {
      'key': key,
      'amount': amount * 100, // ✅ FIXED (convert to paisa)
      'order_id': razorpayOrderId,
      'name': 'Hungzo',
      'description': 'Order Payment',
      'theme': {'color': '#16AB88'},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Payment failed to start");
    }
  }

  // ================= PAYMENT SUCCESS =================
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("✅ Payment Success");

    if (_orderId == null) {
      isLoading.value = false;
      return;
    }

    // Show loader
    Get.dialog(
      const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Confirming your order..."),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // 🔁 Poll backend until webhook updates order
    await _waitForPaymentConfirmation(_orderId!);
  }

  // ================= POLLING =================
  Future<void> _waitForPaymentConfirmation(String orderId) async {
    const int maxAttempts = 6;

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 2));

      try {
        final token = await _storage.read(key: 'accessToken');

        final res = await http.get(
          Uri.parse("${ApiConstants.baseURL}orders/my"),
          headers: {
            "Authorization": "Bearer $token",
          },
        );

        final data = jsonDecode(res.body);
        final orders = data["orders"] as List;

        final order = orders.firstWhere(
          (o) => o["_id"] == orderId,
          orElse: () => null,
        );

        if (order != null) {
          if (order["paymentStatus"] == "paid") {
            Get.back();
            isLoading.value = false;
            paymentCompleted.value = true;
            return;
          }

          if (order["paymentStatus"] == "failed") {
            Get.back();
            isLoading.value = false;
            Get.snackbar("Error", "Payment failed");
            return;
          }
        }

      } catch (e) {
        debugPrint("Polling error: $e");
      }
    }

    Get.back();
    isLoading.value = false;
    Get.snackbar("Pending", "Payment confirmation taking time");
  }

  // ================= PAYMENT ERROR =================
  void _handlePaymentError(PaymentFailureResponse response) {
    isLoading.value = false;

    Get.snackbar(
      "Payment Failed",
      response.message ?? "Error occurred",
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  // ================= EXTERNAL WALLET =================
  void _handleExternalWallet(ExternalWalletResponse response) {
    isLoading.value = false;

    Get.snackbar(
      "Wallet",
      response.walletName ?? "External wallet selected",
    );
  }
}