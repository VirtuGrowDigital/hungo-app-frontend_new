// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
//
// import '../../controllers/auth_controller.dart';
// import '../../data/models/login_and_registration_flow/registration/RegisterModel.dart';
// import '../../model/user_model.dart';
// import '../../utils/ColorConstants.dart';
// import '../../utils/snack_bar.dart';
// import '../../utils/string_constants.dart';
//
// class CreateAccountScreen extends StatefulWidget {
//   final User user;
//
//   const CreateAccountScreen({
//     super.key,
//     required this.user,
//   });
//
//   @override
//   State<CreateAccountScreen> createState() =>
//       _CreateAccountScreenState();
// }
//
// class _CreateAccountScreenState extends State<CreateAccountScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final AuthController _authController = Get.find<AuthController>();
//
//   // Image
//   File? _profileImage;
//   final ImagePicker _picker = ImagePicker();
//
//   // Controllers
//   final _fullNameController = TextEditingController();
//   final _restaurantNameController = TextEditingController();
//   final _restaurantAddressController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _stateController = TextEditingController();
//   final _pincodeController = TextEditingController();
//   final _gstController = TextEditingController();
//   final _fssaiController = TextEditingController();
//
//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _restaurantNameController.dispose();
//     _restaurantAddressController.dispose();
//     _cityController.dispose();
//     _stateController.dispose();
//     _pincodeController.dispose();
//     _gstController.dispose();
//     _fssaiController.dispose();
//     super.dispose();
//   }
//
//   /// ================= IMAGE PICKER =================
//   Future<void> _pickImage() async {
//     final XFile? image = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 80,
//     );
//
//     if (image != null) {
//       setState(() {
//         _profileImage = File(image.path);
//       });
//     }
//   }
//
//   /// ================= VALIDATIONS =================
//   String? _validateRequired(String? value, String field) {
//     if (value == null || value.trim().isEmpty) {
//       return '$field is required';
//     }
//     return null;
//   }
//
//   String? _validatePincode(String? value) {
//     if (value == null || value.isEmpty) return 'Pincode is required';
//     if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Invalid pincode';
//     return null;
//   }
//
//   String? _validateGST(String? value) {
//     if (value == null || value.isEmpty) return null;
//     final gstRegex = RegExp(
//         r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
//     if (!gstRegex.hasMatch(value.toUpperCase())) {
//       return 'Invalid GST number';
//     }
//     return null;
//   }
//
//   String? _validateFSSAI(String? value) {
//     if (value == null || value.isEmpty) return null;
//     if (!RegExp(r'^[0-9]{14}$').hasMatch(value)) {
//       return 'Invalid FSSAI number';
//     }
//     return null;
//   }
//
//   String? _validateGstOrFssai() {
//     if (_gstController.text.isEmpty &&
//         _fssaiController.text.isEmpty) {
//       return 'Either GST or FSSAI number is required';
//     }
//     return null;
//   }
//
//   /// ================= SUBMIT =================
//   void _handleSubmit() async {
//     final isValid = _formKey.currentState!.validate();
//     final extraError = _validateGstOrFssai();
//
//     if (!isValid || extraError != null) {
//       CustomSnackBar(extraError ?? 'Please fix errors', 'E');
//       return;
//     }
//
//     try {
//       /// SHOW LOADER
//       Get.dialog(
//         const Center(child: CircularProgressIndicator()),
//         barrierDismissible: false,
//       );
//
//       /// 🔼 UPLOAD IMAGE IF EXISTS
//       String profileImageUrl = '';
//       if (_profileImage != null) {
//         profileImageUrl = await _authController.uploadProfileImage(
//           image: _profileImage!,
//           uid: widget.user.uid,
//         );
//       }
//
//       /// CREATE USER MODEL
//       final userModel = UserModel(
//         uid: widget.user.uid,
//         phone: widget.user.phoneNumber ?? '',
//         fullName: _fullNameController.text.trim(),
//         restaurantName: _restaurantNameController.text.trim(),
//         restaurantAddress: _restaurantAddressController.text.trim(),
//         city: _cityController.text.trim(),
//         state: _stateController.text.trim(),
//         pincode: _pincodeController.text.trim(),
//         gstNumber: _gstController.text.trim(),
//         fssaiLicenseNumber: _fssaiController.text.trim(),
//         email: widget.user.email ?? '',
//         profilePhoto: profileImageUrl,
//         role: 'restaurant',
//         fcmToken: '',
//         createdAt: DateTime.now(),
//         isProfileCompleted: true,
//         isActive: true,
//       );
//
//       /// SAVE TO FIRESTORE
//       await _authController.createUserProfile(userModel,);
//
//       Get.back(); // close loader
//     } catch (e) {
//       Get.back();
//       CustomSnackBar('Something went wrong', 'E');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: ColorConstants.scaffoldBackground,
//       appBar: AppBar(
//         backgroundColor: ColorConstants.scaffoldBackground,
//         elevation: 0,
//         leading: BackButton(color: Colors.black),
//       ),
//       body: SafeArea(
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 10),
//
//                 /// PROFILE IMAGE
//                 Center(
//                   child: Stack(
//                     children: [
//                       CircleAvatar(
//                         radius: 50,
//                         backgroundColor: ColorConstants.divider,
//                         backgroundImage:
//                         _profileImage != null ? FileImage(_profileImage!) : null,
//                         child: _profileImage == null
//                             ? const Icon(Icons.person,
//                             size: 50, color: Colors.white)
//                             : null,
//                       ),
//                       Positioned(
//                         bottom: 0,
//                         right: 0,
//                         child: GestureDetector(
//                           onTap: _pickImage,
//                           child: const CircleAvatar(
//                             radius: 16,
//                             backgroundColor: ColorConstants.error,
//                             child: Icon(Icons.camera_alt,
//                                 size: 16, color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 _label(TextConstants.fullName),
//                 _input(TextConstants.enterFullName,
//                     controller: _fullNameController,
//                     validator: (v) => _validateRequired(v, 'Full name')),
//
//                 _label(TextConstants.restaurantName),
//                 _input(TextConstants.enterRestaurantName,
//                     controller: _restaurantNameController,
//                     validator: (v) =>
//                         _validateRequired(v, 'Restaurant name')),
//
//                 _label(TextConstants.restaurantAddress),
//                 _input(TextConstants.enterRestaurantAddress,
//                     controller: _restaurantAddressController,
//                     validator: (v) =>
//                         _validateRequired(v, 'Restaurant address')),
//
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _label(TextConstants.city),
//                           _input(TextConstants.enterCity,
//                               controller: _cityController,
//                               validator: (v) =>
//                                   _validateRequired(v, 'City')),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _label(TextConstants.state),
//                           _input(TextConstants.enterState,
//                               controller: _stateController,
//                               validator: (v) =>
//                                   _validateRequired(v, 'State')),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 _label(TextConstants.pincode),
//                 _input(TextConstants.enterPincode,
//                     controller: _pincodeController,
//                     keyboard: TextInputType.number,
//                     maxLength: 6,
//                     validator: _validatePincode,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
//
//                 _label(TextConstants.gstNumber),
//                 _input(TextConstants.enterGst,
//                     controller: _gstController,
//                     validator: _validateGST,
//                     textCapitalization: TextCapitalization.characters,
//                     maxLength: 15),
//
//                 _label(TextConstants.fssaiNumber),
//                 _input(TextConstants.enterFssai,
//                     controller: _fssaiController,
//                     keyboard: TextInputType.number,
//                     validator: _validateFSSAI,
//                     maxLength: 14,
//                     inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
//
//                 const SizedBox(height: 25),
//
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: _handleSubmit,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: ColorConstants.success,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                     ),
//                     child: const Text(
//                       TextConstants.submit,
//                       style: TextStyle(fontSize: 18, color: Colors.white),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _label(String text) => Padding(
//     padding: const EdgeInsets.only(top: 12, bottom: 4),
//     child: Text(
//       text,
//       style: const TextStyle(
//         color: ColorConstants.success,
//         fontWeight: FontWeight.w600,
//       ),
//     ),
//   );
//
//   Widget _input(
//       String hint, {
//         TextEditingController? controller,
//         TextInputType keyboard = TextInputType.text,
//         String? Function(String?)? validator,
//         int? maxLength,
//         List<TextInputFormatter>? inputFormatters,
//         TextCapitalization textCapitalization = TextCapitalization.none,
//       }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: keyboard,
//       validator: validator,
//       maxLength: maxLength,
//       inputFormatters: inputFormatters,
//       textCapitalization: textCapitalization,
//       decoration: InputDecoration(
//         hintText: hint,
//         counterText: '',
//         filled: true,
//         fillColor: Colors.white,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../data/models/login_and_registration_flow/registration/RegisterModel.dart';
import '../../model/user_model.dart';
import '../../utils/ColorConstants.dart';
import '../../utils/snack_bar.dart';
import '../../utils/string_constants.dart';

class CreateAccountScreen extends StatefulWidget {
  final User user;

  const CreateAccountScreen({
    super.key,
    required this.user,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}
class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

  /// IMAGE
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  /// CONTROLLERS
  final _fullNameController = TextEditingController();
  final _restaurantNameController = TextEditingController();
  final _restaurantAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _gstController = TextEditingController();
  final _fssaiController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstController.dispose();
    _fssaiController.dispose();
    super.dispose();
  }

  /// ================= IMAGE PICKER =================
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  /// ================= VALIDATIONS =================
  String? _validateRequired(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.isEmpty) return 'Pincode is required';
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) return 'Invalid pincode';
    return null;
  }

  // GST Validation – nullable
  String? _validateGST(String? value) {
    if (value == null || value.trim().isEmpty) return null; // nullable
    final gstRegex = RegExp(
        r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
    if (!gstRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid GST number';
    }
    return null;
  }

  // FSSAI Validation – nullable
  String? _validateFSSAI(String? value) {
    if (value == null || value.trim().isEmpty) return null; // nullable
    if (!RegExp(r'^[0-9]{14}$').hasMatch(value)) {
      return 'Invalid FSSAI number';
    }
    return null;
  }

  // Combined optional check (optional but can be used)
  String? _validateGstOrFssai() {
    final gstText = _gstController.text.trim();
    final fssaiText = _fssaiController.text.trim();

    // If user entered GST, validate format
    if (gstText.isNotEmpty) {
      final gstError = _validateGST(gstText);
      if (gstError != null) return gstError;
    }

    // If user entered FSSAI, validate format
    if (fssaiText.isNotEmpty) {
      final fssaiError = _validateFSSAI(fssaiText);
      if (fssaiError != null) return fssaiError;
    }

    // Both empty is allowed (fully nullable)
    return null;
  }

  /// ================= SUBMIT =================
  Future<void> _handleSubmit() async {
    final isValid = _formKey.currentState!.validate();
    final extraError = _validateGstOrFssai();

    if (!isValid || extraError != null) {
      CustomSnackBar(extraError ?? 'Please fix errors', 'E');
      return;
    }

    try {
      /// LOADER
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      /// UPLOAD IMAGE
      String profileImageUrl = '';
      if (_profileImage != null) {
        profileImageUrl = await _authController.uploadProfileImage(
          image: _profileImage!,
          uid: widget.user.uid,
        );
      }

      /// BUILD USER MODEL
      final userModel = UserModel(
        uid: widget.user.uid,
        phone: widget.user.phoneNumber ?? '',
        fullName: _fullNameController.text.trim(),
        restaurantName: _restaurantNameController.text.trim(),
        restaurantAddress: _restaurantAddressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty
            ? null
            : _gstController.text.trim(),
        fssaiLicenseNumber: _fssaiController.text.trim().isEmpty
            ? null
            : _fssaiController.text.trim(),
        email: widget.user.email ?? '',
        profilePhoto: profileImageUrl,
        role: 'restaurant',
        fcmToken: '',
        createdAt: DateTime.now(),
        isProfileCompleted: true,
        isActive: true,
      );

      /// SAVE PROFILE (includes backend login + register)
      await _authController.createUserProfile(userModel);

      Get.back(); // close loader
      CustomSnackBar('Profile updated successfully', 'S');
    } catch (e) {
      Get.back();
      print("Profile update error: $e");
      CustomSnackBar('Something went wrong', 'E');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ColorConstants.scaffoldBackground,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                /// PROFILE IMAGE
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: ColorConstants.divider,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : null,
                        child: _profileImage == null
                            ? const Icon(Icons.person,
                            size: 50, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: ColorConstants.error,
                            child: Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _label(TextConstants.fullName),
                _input(TextConstants.enterFullName,
                    controller: _fullNameController,
                    validator: (v) => _validateRequired(v, 'Full name')),

                _label(TextConstants.restaurantName),
                _input(TextConstants.enterRestaurantName,
                    controller: _restaurantNameController,
                    validator: (v) =>
                        _validateRequired(v, 'Restaurant name')),

                _label(TextConstants.restaurantAddress),
                _input(TextConstants.enterRestaurantAddress,
                    controller: _restaurantAddressController,
                    validator: (v) =>
                        _validateRequired(v, 'Restaurant address')),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(TextConstants.city),
                          _input(TextConstants.enterCity,
                              controller: _cityController,
                              validator: (v) =>
                                  _validateRequired(v, 'City')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label(TextConstants.state),
                          _input(TextConstants.enterState,
                              controller: _stateController,
                              validator: (v) =>
                                  _validateRequired(v, 'State')),
                        ],
                      ),
                    ),
                  ],
                ),

                _label(TextConstants.pincode),
                _input(TextConstants.enterPincode,
                    controller: _pincodeController,
                    keyboard: TextInputType.number,
                    maxLength: 6,
                    validator: _validatePincode,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ]),

                _label(TextConstants.gstNumber),
                _input(TextConstants.enterGst,
                    controller: _gstController,
                    validator: _validateGST,
                    textCapitalization:
                    TextCapitalization.characters,
                    maxLength: 15),

                _label(TextConstants.fssaiNumber),
                _input(TextConstants.enterFssai,
                    controller: _fssaiController,
                    keyboard: TextInputType.number,
                    validator: _validateFSSAI,
                    maxLength: 14,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ]),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      TextConstants.submit,
                      style:
                      TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: ColorConstants.success,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _input(
      String hint, {
        TextEditingController? controller,
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
        TextCapitalization textCapitalization = TextCapitalization.none,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
