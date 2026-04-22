// import 'dart:io';
//
// import 'package:dio/dio.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:get/get.dart';
//
// import '../bindings/home_binding.dart';
// import '../constants/constants.dart';
// import '../data/models/login_and_registration_flow/registration/RegisterModel.dart';
// import '../model/user_model.dart';
// import '../screens/auth/create_account.dart';
// import '../screens/home_view.dart';
// import '../screens/auth/login/otp_verification.dart';
// import '../services/Api/api_services.dart';
// import '../utils/flutter_toast.dart';
// import '../utils/snack_bar.dart';
// import '../utils/string_constants.dart';
//
// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   late final Dio dio;
//   final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
//   final isLoading = false.obs;
//   final isVerifying = false.obs;
//   final isResending = false.obs;
//
//   int? _resendToken;
//
//   /// ================= PHONE AUTH =================
//   Future<void> verifyPhone({required String phone}) async {
//     try {
//       isLoading.value = true;
//
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phone,
//         verificationCompleted: (_) {},
//
//         verificationFailed: (e) {
//           isLoading.value = false;
//           CustomSnackBar(
//             e.message ?? TextConstants.verificationFailed,
//             'E',
//           );
//         },
//
//         codeSent: (verificationId, resendToken) {
//           _resendToken = resendToken;
//           isLoading.value = false;
//
//           Get.to(() => OTPVerificationScreen(
//             phoneNumber: phone,
//             verificationId: verificationId,
//           ));
//         },
//
//         codeAutoRetrievalTimeout: (_) {
//           isLoading.value = false;
//         },
//       );
//     } catch (e) {
//       isLoading.value = false;
//       CustomSnackBar(e.toString(), 'E');
//     }
//   }
//
//   /// ================= VERIFY OTP =================
//   Future<void> verifyOTP({
//     required String otp,
//     required String verificationId,
//   }) async {
//     if (otp.length != 6) {
//       CustomSnackBar(TextConstants.enterCompleteOtp, 'E');
//       return;
//     }
//
//     try {
//       isVerifying.value = true;
//
//       final credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: otp,
//       );
//
//       final userCred =
//       await _auth.signInWithCredential(credential);
//
//       await _handleUserLogin(userCred.user!);
//     } on FirebaseAuthException catch (e) {
//       CustomSnackBar(
//         e.message ?? TextConstants.invalidOtp,
//         'E',
//       );
//     } catch (_) {
//       CustomSnackBar(TextConstants.somethingWentWrong, 'E');
//     } finally {
//       isVerifying.value = false;
//     }
//   }
//
//   /// ================= USER CHECK =================
//   Future<void> _handleUserLogin(User user) async {
//     final doc =
//     await _db.collection('users').doc(user.uid).get();
//
//     /// ✅ USER EXISTS → HOME
//     if (doc.exists) {
//       try {
//         final user = FirebaseAuth.instance.currentUser;
//
//         if (user == null) {
//           throw Exception('Firebase user not found');
//         }
//
//         // 1️⃣ Get Firebase ID Token
//         final firebaseToken = await user.getIdToken(true);
//
//         // 2️⃣ Call Backend Firebase Login API
//         final apiService = ApiService(dio: Dio()); // no dio null
//         await apiService.firebaseLogin(firebaseToken!);
//
//         // 3️⃣ Navigate ONLY after API success
//         Get.offAll(
//               () => const HomeView(),
//           binding: HomeBinding(),
//         );
//       } catch (e) {
//         Message_Utils.displayToast(
//           'Login failed. Please try again.',
//         );
//       }
//     }
//
//     /// ❌ NEW USER → CREATE ACCOUNT
//     else {
//       Get.offAll(() => CreateAccountScreen(user: user));
//     }
//   }
//
//   /// ================= CREATE USER AFTER SIGNUP =================
//   Future<void> createUserProfile(UserModel userModel) async {
//     try {
//       // 1️⃣ Save user in Firestore
//       await _db
//           .collection('users')
//           .doc(userModel.uid)
//           .set(userModel.toMap());
//
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) {
//         throw Exception('Firebase user not found');
//       }
//
//       // 2️⃣ Get backend token (already saved after firebaseLogin)
//       final token = await secureStorage.read(key: Constants.accessToken);
//       if (token == null) {
//         throw Exception('Backend token missing');
//       }
//
//       // 3️⃣ BUILD REQUEST BODY ✅
//       final Map<String, dynamic> requestBody = {
//         "ownerName": userModel.fullName,
//         "restaurantName": userModel.restaurantName,
//         "gst": userModel.gstNumber,
//         "fssai": userModel.fssaiLicenseNumber,
//         "address": {
//           "label": userModel.city,
//           "city": userModel.city,
//           "state": userModel.state,
//           "pincode": userModel.pincode,
//         }
//       };
//
//       // 4️⃣ Call register API
//       // final apiService = ApiService();
//       final apiService = ApiService(dio: Dio()); // no dio null
//       final result =
//       await apiService.firebaseRegister(requestBody);
//
//       if (result.status == true) {
//         Get.offAll(
//               () => const HomeView(),
//           binding: HomeBinding(),
//         );
//       } else {
//         Message_Utils.displayToast(result.message ?? 'Registration failed');
//       }
//     } catch (e) {
//       Message_Utils.displayToast(e.toString());
//     }
//   }
//   Future<String?> getAccessToken() async {
//     return await secureStorage.read(key: 'accessToken');
//   }
//
//   Future<String?> getRefreshToken() async {
//     return await secureStorage.read(key: 'refreshToken');
//   }
//
//   /// ================= RESEND OTP =================
//   Future<void> resendOTP(String phone) async {
//     try {
//       isResending.value = true;
//
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phone,
//         forceResendingToken: _resendToken,
//
//         verificationCompleted: (_) {},
//
//         verificationFailed: (e) {
//           CustomSnackBar(
//             e.message ?? TextConstants.verificationFailed,
//             'E',
//           );
//         },
//
//         codeSent: (_, resendToken) {
//           _resendToken = resendToken;
//           CustomSnackBar(TextConstants.otpResent, 'S');
//         },
//
//         codeAutoRetrievalTimeout: (_) {},
//       );
//     } finally {
//       isResending.value = false;
//     }
//   }
//
//   /// ================= AUTH CHECK =================
//   bool isUserLoggedIn() {
//     return _auth.currentUser != null;
//   }
//
//   /// ================= UPLOAD PROFILE IMAGE =================
//   Future<String> uploadProfileImage({
//     required File image,
//     required String uid,
//   }) async {
//     try {
//       final ref = FirebaseStorage.instance
//           .ref()
//           .child('users/profile_photos/$uid.jpg');
//
//       final uploadTask = ref.putFile(image);
//
//       await uploadTask;
//
//       return await ref.getDownloadURL();
//     } catch (e) {
//       CustomSnackBar('Image upload failed', 'E');
//       rethrow;
//     }
//   }
// }

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../bindings/home_binding.dart';
import '../constants/constants.dart';
import '../data/models/login_and_registration_flow/registration/RegisterModel.dart';
import '../screens/auth/create_account.dart';
import '../screens/auth/login/otp_verification.dart';
import '../screens/home_view.dart';
import '../services/Api/api_services.dart';
import '../utils/flutter_toast.dart';
import '../utils/snack_bar.dart';
import '../utils/string_constants.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final isLoading = false.obs;
  final isVerifying = false.obs;
  final isResending = false.obs;

  int? _resendToken;

  /// ================= PHONE AUTH =================
  Future<void> verifyPhone({required String phone}) async {
    try {
      isLoading.value = true;

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          isLoading.value = false;
          print(
            'Phone verification failed: code=${e.code}, message=${e.message}',
          );
          print('Phone verification exception: $e');
          CustomSnackBar(
            e.message ?? TextConstants.verificationFailed,
            'E',
          );
        },
        codeSent: (verificationId, resendToken) {
          _resendToken = resendToken;
          isLoading.value = false;

          Get.to(() => OTPVerificationScreen(
                phoneNumber: phone,
                verificationId: verificationId,
              ));
        },
        codeAutoRetrievalTimeout: (_) {
          isLoading.value = false;
        },
      );
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      print(
        'verifyPhoneNumber threw FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      print('verifyPhoneNumber exception: $e');
      CustomSnackBar(e.message ?? TextConstants.verificationFailed, 'E');
    } catch (e) {
      isLoading.value = false;
      print('verifyPhoneNumber threw unexpected error: $e');
      CustomSnackBar(e.toString(), 'E');
    }
  }

  /// ================= VERIFY OTP =================
  Future<void> verifyOTP({
    required String otp,
    required String verificationId,
  }) async {
    if (otp.length != 6) {
      CustomSnackBar(TextConstants.enterCompleteOtp, 'E');
      return;
    }

    try {
      isVerifying.value = true;

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCred = await _auth.signInWithCredential(credential);

      await _handleUserLogin(userCred.user!);
    } on FirebaseAuthException catch (e) {
      CustomSnackBar(
        e.message ?? TextConstants.invalidOtp,
        'E',
      );
    } catch (_) {
      CustomSnackBar(TextConstants.somethingWentWrong, 'E');
    } finally {
      isVerifying.value = false;
    }
  }

  /// ================= USER CHECK =================
  Future<void> _handleUserLogin(User user) async {
    final doc = await _db.collection('users').doc(user.uid).get();

    /// ✅ EXISTING USER
    if (doc.exists) {
      try {
        final firebaseToken = await user.getIdToken(true);
        print("Firebase tockan $firebaseToken");
        await secureStorage.write(
            key: Constants.fcmToken, value: '$firebaseToken');

        final apiService = ApiService(dio: Dio());
        await apiService.firebaseLogin(firebaseToken!);

        Get.offAll(
          () => const HomeView(),
          binding: HomeBinding(),
        );
      } catch (e) {
        Message_Utils.displayToast('Login failed. Please try again.');
      }
    }

    /// ❌ NEW USER
    else {
      final firebaseToken = await user.getIdToken(true);
      print("Firebase tockan $firebaseToken");
      await secureStorage.write(
          key: Constants.fcmToken, value: '$firebaseToken');

      final apiService = ApiService(dio: Dio());
      await apiService.firebaseLogin(firebaseToken!);

      Get.offAll(() => CreateAccountScreen(user: user));
    }
  }

  /// ================= CREATE USER AFTER SIGNUP =================
  Future<void> createUserProfile(UserModel userModel) async {
    try {
      /// 1️⃣ SAVE USER TO FIRESTORE
      print("SAVE USER TO FIRESTORE");
      await _db.collection('users').doc(userModel.uid).set(userModel.toMap());

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Firebase user not found');
      }

      /// 2️⃣ FIREBASE LOGIN (GENERATES BACKEND TOKEN)
      final firebaseToken = await user.getIdToken(true);
      final apiService = ApiService(dio: Dio());
      await apiService.firebaseLogin(firebaseToken!);

      /// 3️⃣ CONFIRM TOKEN EXISTS
      // await secureStorage.write(
      //   key: Constants.accessToken,
      //   value: 'firebaseToken',
      // );
      final token = await secureStorage.read(key: Constants.fcmToken);
      if (token == null) {
        throw Exception('Backend token missing');
      }

      /// 4️⃣ REGISTER USER IN BACKEND
      final Map<String, dynamic> requestBody = {
        "ownerName": userModel.fullName,
        "restaurantName": userModel.restaurantName,
        "gst": userModel.gstNumber,
        "fssai": userModel.fssaiLicenseNumber,
        "address": {
          "label": userModel.city,
          "city": userModel.city,
          "state": userModel.state,
          "pincode": userModel.pincode,
        }
      };
      print("SAVE USER TO FIRESTORE $requestBody");
      final result = await apiService.firebaseRegister(requestBody);

      if (result.message == "Restaurant registered successfully" ||
          result.message == "Restaurant already registered") {
        print("result.status ${result.status}");
        Get.offAll(
          () => const HomeView(),
          binding: HomeBinding(),
        );
      } else {
        print("SAVE USER TO FIRESTORE ${result.message}");

        Message_Utils.displayToast(result.message ?? 'Registration failed');
      }
    } catch (e) {
      print("SAVE USER TO FIRESTORE ${e}");

      Message_Utils.displayToast(e.toString());
    }
  }

  /// ================= RESEND OTP =================
  Future<void> resendOTP(String phone) async {
    try {
      isResending.value = true;

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          print(
            'Resend OTP failed: code=${e.code}, message=${e.message}',
          );
          print('Resend OTP exception: $e');
          CustomSnackBar(
            e.message ?? TextConstants.verificationFailed,
            'E',
          );
        },
        codeSent: (_, resendToken) {
          _resendToken = resendToken;
          CustomSnackBar(TextConstants.otpResent, 'S');
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      print(
        'resendOTP threw FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      print('resendOTP exception: $e');
      CustomSnackBar(e.message ?? TextConstants.verificationFailed, 'E');
    } finally {
      isResending.value = false;
    }
  }

  /// ================= AUTH CHECK =================
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// ================= UPLOAD PROFILE IMAGE =================
  Future<String> uploadProfileImage({
    required File image,
    required String uid,
  }) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('users/profile_photos/$uid.jpg');

      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      CustomSnackBar('Image upload failed', 'E');
      rethrow;
    }
  }
}
