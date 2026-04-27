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

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../bindings/home_binding.dart';
import '../constants/constants.dart';
import '../model/user_model.dart';
import '../screens/auth/login/login_screen.dart';
import '../screens/auth/login/otp_verification.dart';
import '../screens/home_view.dart';
import '../services/Api/api_services.dart';
import '../utils/snack_bar.dart';
import '../utils/string_constants.dart';
import 'wallet_controller.dart';

class AuthController extends GetxController {
  static const Duration _otpRequestCooldown = Duration(seconds: 30);
  static const Duration _resendCooldownDuration = Duration(seconds: 30);
  static const int _maxOtpRequestsPerSession = 5;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final isLoading = false.obs;
  final isVerifying = false.obs;
  final isResending = false.obs;
  final resendCooldownSeconds = 0.obs;
  final isLoggedIn = false.obs;
  final isSessionReady = false.obs;

  int? _resendToken;
  int _otpRequestsInSession = 0;
  String? _lastRequestedPhone;
  String? _activeVerificationId;
  DateTime? _lastOtpRequestAt;
  Timer? _resendCooldownTimer;
  StreamSubscription<User?>? _authSubscription;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.authStateChanges().listen((_) {
      refreshSessionState();
    });
    refreshSessionState();
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _resendCooldownTimer?.cancel();
    super.onClose();
  }

  bool get canRequestOtp => !isLoading.value && !_isInRequestCooldown;
  bool get canResendOtp =>
      !isResending.value &&
      resendCooldownSeconds.value == 0 &&
      _resendToken != null &&
      _lastRequestedPhone != null;

  bool get hasAuthenticatedSession {
    return isLoggedIn.value;
  }

  bool get _isInRequestCooldown {
    if (_lastOtpRequestAt == null) {
      return false;
    }

    return DateTime.now().difference(_lastOtpRequestAt!) < _otpRequestCooldown;
  }

  int get remainingRequestCooldownSeconds {
    if (_lastOtpRequestAt == null) {
      return 0;
    }

    final remaining =
        _otpRequestCooldown - DateTime.now().difference(_lastOtpRequestAt!);
    return remaining.isNegative ? 0 : remaining.inSeconds + 1;
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    resendCooldownSeconds.value = _resendCooldownDuration.inSeconds;
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final nextValue = resendCooldownSeconds.value - 1;
      if (nextValue <= 0) {
        resendCooldownSeconds.value = 0;
        timer.cancel();
        return;
      }

      resendCooldownSeconds.value = nextValue;
    });
  }

  Future<bool> hasValidSession() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return false;
    }

    final accessToken = await secureStorage.read(key: Constants.accessToken);
    final refreshToken = await secureStorage.read(key: Constants.refreshToken);
    return accessToken != null && refreshToken != null;
  }

  Future<void> refreshSessionState() async {
    isLoggedIn.value = await hasValidSession();
    isSessionReady.value = true;

    if (isLoggedIn.value && Get.isRegistered<WalletController>()) {
      unawaited(Get.find<WalletController>().fetchWallet());
    }
  }

  Future<void> logout() async {
    _resendCooldownTimer?.cancel();
    resendCooldownSeconds.value = 0;
    _resendToken = null;
    _activeVerificationId = null;
    _lastRequestedPhone = null;
    _lastOtpRequestAt = null;
    _otpRequestsInSession = 0;

    await _auth.signOut();
    await secureStorage.delete(key: Constants.accessToken);
    await secureStorage.delete(key: Constants.refreshToken);
    await secureStorage.delete(key: Constants.fcmToken);
    isLoggedIn.value = false;
    isSessionReady.value = true;
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().clearWallet();
    }
  }

  Future<bool> ensureAuthenticated({
    String? title,
    String? message,
  }) async {
    if (await hasValidSession()) {
      isLoggedIn.value = true;
      isSessionReady.value = true;
      return true;
    }

    final bool? shouldLogin = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title ?? 'Login required'),
        content: Text(
          message ?? 'Please log in to continue with this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Login'),
          ),
        ],
      ),
    );

    if (shouldLogin != true) {
      return false;
    }

    final bool? didLogin = await Get.to<bool>(
      () => const LoginScreen(returnResultOnSuccess: true),
    );

    await refreshSessionState();
    return didLogin == true || isUserLoggedIn();
  }

  /// ================= PHONE AUTH =================
  Future<void> verifyPhone({
    required String phone,
    bool returnResultOnSuccess = false,
  }) async {
    final normalizedPhone = phone.trim();

    if (normalizedPhone.isEmpty) {
      CustomSnackBar(TextConstants.invalidPhoneNumber, 'E');
      return;
    }

    if (isLoading.value) {
      return;
    }

    if (_otpRequestsInSession >= _maxOtpRequestsPerSession) {
      CustomSnackBar(TextConstants.tooManyOtpAttempts, 'E');
      return;
    }

    if (_isInRequestCooldown) {
      CustomSnackBar(
        'Please wait ${remainingRequestCooldownSeconds}s before requesting another OTP.',
        'W',
      );
      return;
    }

    try {
      isLoading.value = true;
      _lastRequestedPhone = normalizedPhone;
      _lastOtpRequestAt = DateTime.now();
      _otpRequestsInSession += 1;

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (credential) async {
          try {
            final userCred = await _auth.signInWithCredential(credential);
            final signedInUser = userCred.user;
            if (signedInUser == null) {
              throw FirebaseAuthException(
                code: 'user-not-found',
                message: 'Unable to complete sign in.',
              );
            }

            await _handleUserLogin(
              signedInUser,
              returnResultOnSuccess: returnResultOnSuccess,
            );
          } on FirebaseAuthException catch (e) {
            CustomSnackBar(
              e.message ?? TextConstants.verificationFailed,
              'E',
            );
          } catch (_) {
            CustomSnackBar(TextConstants.somethingWentWrong, 'E');
          } finally {
            isLoading.value = false;
          }
        },
        verificationFailed: (e) {
          isLoading.value = false;
          debugPrint(
            'Phone verification failed: code=${e.code}, message=${e.message}',
          );
          debugPrint('Phone verification exception: $e');
          CustomSnackBar(
            e.message ?? TextConstants.verificationFailed,
            'E',
          );
        },
        codeSent: (verificationId, resendToken) {
          _resendToken = resendToken;
          _activeVerificationId = verificationId;
          isLoading.value = false;
          _startResendCooldown();

          final otpScreen = OTPVerificationScreen(
            phoneNumber: normalizedPhone,
            verificationId: verificationId,
            returnResultOnSuccess: returnResultOnSuccess,
          );

          if (returnResultOnSuccess) {
            Get.off(() => otpScreen);
          } else {
            Get.to(() => otpScreen);
          }
        },
        codeAutoRetrievalTimeout: (_) {
          isLoading.value = false;
        },
      );
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      debugPrint(
        'verifyPhoneNumber threw FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      debugPrint('verifyPhoneNumber exception: $e');
      CustomSnackBar(e.message ?? TextConstants.verificationFailed, 'E');
    } catch (e) {
      isLoading.value = false;
      debugPrint('verifyPhoneNumber threw unexpected error: $e');
      CustomSnackBar(e.toString(), 'E');
    }
  }

  /// ================= VERIFY OTP =================
  Future<void> verifyOTP({
    required String otp,
    required String verificationId,
    bool returnResultOnSuccess = false,
  }) async {
    if (otp.length != 6) {
      CustomSnackBar(TextConstants.enterCompleteOtp, 'E');
      return;
    }

    try {
      isVerifying.value = true;

      final activeVerificationId = _activeVerificationId;
      if (activeVerificationId != null &&
          activeVerificationId != verificationId) {
        CustomSnackBar(
          'A newer OTP was requested. Please use the latest code.',
          'W',
        );
        return;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCred = await _auth.signInWithCredential(credential);

      await _handleUserLogin(
        userCred.user!,
        returnResultOnSuccess: returnResultOnSuccess,
      );
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
  Future<void> _handleUserLogin(
    User user, {
    required bool returnResultOnSuccess,
  }) async {
    final doc = await _db.collection('users').doc(user.uid).get();
    final isNewUser = !doc.exists;

    try {
      final firebaseToken = await user.getIdToken(true);
      debugPrint(
        'Firebase token refreshed for ${isNewUser ? 'new' : 'existing'} user.',
      );
      await secureStorage.write(
        key: Constants.fcmToken,
        value: '$firebaseToken',
      );

      final apiService = ApiService(dio: Dio());
      await apiService.firebaseLogin(firebaseToken!);

      if (isNewUser) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'phone': user.phoneNumber ?? '',
          'email': user.email ?? '',
          'fullName': '',
          'profilePhoto': '',
          'role': 'restaurant',
          'fcmToken': '',
          'createdAt': Timestamp.now(),
          'isProfileCompleted': false,
          'isActive': true,
        }, SetOptions(merge: true));
      }

      isLoggedIn.value = true;
      isSessionReady.value = true;
      _finishAuthSuccess(
        returnResultOnSuccess: returnResultOnSuccess,
      );
    } catch (e) {
      CustomSnackBar('Login failed. Please try again.', 'E');
    }
  }

  /// ================= CREATE USER AFTER SIGNUP =================
  Future<void> createUserProfile(
    UserModel userModel, {
    bool returnResultOnSuccess = false,
  }) async {
    try {
      /// 1️⃣ SAVE USER TO FIRESTORE
      debugPrint('Saving user profile to Firestore.');
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
      final token = await secureStorage.read(key: Constants.accessToken);
      if (token == null) {
        throw Exception('Backend token missing');
      }
      isLoggedIn.value = true;
      isSessionReady.value = true;

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
      debugPrint('Submitting restaurant registration payload.');
      final result = await apiService.firebaseRegister(requestBody);

      if (result.message == "Restaurant registered successfully" ||
          result.message == "Restaurant already registered") {
        debugPrint('Restaurant profile saved successfully.');
        CustomSnackBar('Profile updated successfully', 'S');
        _finishAuthSuccess(
          returnResultOnSuccess: returnResultOnSuccess,
        );
      } else {
        debugPrint('Restaurant registration failed: ${result.message}');
        CustomSnackBar(result.message, 'E');
      }
    } catch (e) {
      debugPrint('Failed to save user profile: $e');
      CustomSnackBar(e.toString(), 'E');
    }
  }

  void _finishAuthSuccess({
    required bool returnResultOnSuccess,
  }) {
    if (returnResultOnSuccess && Get.key.currentState?.canPop() == true) {
      Get.back(result: true);
      return;
    }

    Get.offAll(
      () => const HomeView(),
      binding: HomeBinding(),
    );
  }

  /// ================= RESEND OTP =================
  Future<void> resendOTP(String phone) async {
    final normalizedPhone = phone.trim();

    if (normalizedPhone.isEmpty || _lastRequestedPhone == null) {
      CustomSnackBar(TextConstants.invalidPhoneNumber, 'E');
      return;
    }

    if (isResending.value) {
      return;
    }

    if (resendCooldownSeconds.value > 0) {
      CustomSnackBar(
        'Please wait ${resendCooldownSeconds.value}s before resending OTP.',
        'W',
      );
      return;
    }

    if (_resendToken == null) {
      CustomSnackBar(
        'Please request a new OTP from the login screen.',
        'W',
      );
      return;
    }

    try {
      isResending.value = true;

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        forceResendingToken: _resendToken,
        verificationCompleted: (_) {},
        verificationFailed: (e) {
          debugPrint(
            'Resend OTP failed: code=${e.code}, message=${e.message}',
          );
          debugPrint('Resend OTP exception: $e');
          CustomSnackBar(
            e.message ?? TextConstants.verificationFailed,
            'E',
          );
        },
        codeSent: (verificationId, resendToken) {
          _activeVerificationId = verificationId;
          _resendToken = resendToken;
          _lastOtpRequestAt = DateTime.now();
          _startResendCooldown();
          CustomSnackBar(TextConstants.otpResent, 'S');
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'resendOTP threw FirebaseAuthException: code=${e.code}, message=${e.message}',
      );
      debugPrint('resendOTP exception: $e');
      CustomSnackBar(e.message ?? TextConstants.verificationFailed, 'E');
    } finally {
      isResending.value = false;
    }
  }

  /// ================= AUTH CHECK =================
  bool isUserLoggedIn() {
    return isLoggedIn.value;
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
