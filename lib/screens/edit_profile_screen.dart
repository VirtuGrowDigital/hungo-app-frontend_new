import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hungzo_app/services/Api/api_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/ColorConstants.dart';
import 'package:mime/mime.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FlutterSecureStorage secureStorage =
  const FlutterSecureStorage();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();

  String initialName = '';
  String initialEmail = '';
  String initialDob = '';
  String initialGender = '';
  String selectedGender = '';

  File? selectedImage;
  String? profileImageUrl;

  String verificationStatus = "PENDING";
  bool isActive = false;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    dobCtrl.dispose();
    super.dispose();
  }

  /// ================= FETCH PROFILE =================
  Future<void> fetchProfile() async {
    try {
      final token = await secureStorage.read(key: 'accessToken');
      if (token == null) return;

      final response = await http.get(
        Uri.parse("${ApiConstants.baseURL}restaurant/myProfile"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body)["profile"];

        nameCtrl.text = profile["ownerName"] ?? "";
        emailCtrl.text = profile["email"] ?? "";
        phoneCtrl.text = profile["phone"] ?? "";
        dobCtrl.text = _formatDate(profile["dob"]);
        selectedGender = _displayGender(profile["gender"]);
        profileImageUrl = profile["profilePic"];
        selectedImage = null;

        verificationStatus = profile["verificationStatus"] ?? "NOT_SUBMITTED";
        isActive = profile["isActive"] ?? false;

        initialName = nameCtrl.text;
        initialEmail = emailCtrl.text;
        initialDob = dobCtrl.text;
        initialGender = selectedGender;
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// ================= UPDATE PROFILE =================
  // Future<void> updateProfile() async {
  //   final token = await secureStorage.read(key: 'accessToken');
  //   if (token == null) return;
  //
  //   final request = http.MultipartRequest(
  //     "PUT",
  //     Uri.parse("${ApiConstants.baseURL}restaurant/profile"),
  //   );
  //
  //   if (nameCtrl.text.trim() != initialName) {
  //     request.fields["ownerName"] = nameCtrl.text.trim();
  //   }
  //   if (emailCtrl.text.trim() != initialEmail) {
  //     request.fields["email"] = emailCtrl.text.trim();
  //   }
  //   if (selectedImage != null) {
  //     final file = selectedImage!;
  //     final mimeType = lookupMimeType(file.path) ?? "image/jpeg";
  //
  //     request.files.add(
  //       await http.MultipartFile.fromPath(
  //         "profilePic", // ⚠️ must match backend field name
  //         file.path,
  //         contentType: http.MediaType.parse(mimeType),
  //       ),
  //     );
  //   }
  //
  //   if (request.fields.isEmpty && request.files.isEmpty) {
  //     Get.snackbar("No Changes", "Nothing to update");
  //     return;
  //   }
  //
  //   request.headers["Authorization"] = "Bearer $token";
  //
  //   final response = await request.send();
  //
  //   if (response.statusCode == 200) {
  //     Get.snackbar("Success", "Profile updated successfully");
  //     initialName = nameCtrl.text;
  //     initialEmail = emailCtrl.text;
  //   } else {
  //     Get.snackbar("Error", "Update failed");
  //   }
  // }


  Future<void> updateProfile() async {
    const secureStorage = FlutterSecureStorage();
    final token = await secureStorage.read(key: 'accessToken');

    if (token == null) {
      Get.snackbar("Error", "User not authenticated");
      return;
    }

    try {
      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("${ApiConstants.baseURL}restaurant/profile"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      /// Add Name
      if (nameCtrl.text.trim() != initialName) {
        request.fields["ownerName"] = nameCtrl.text.trim();
      }

      /// Add Email
      if (emailCtrl.text.trim() != initialEmail) {
        request.fields["email"] = emailCtrl.text.trim();
      }

      if (dobCtrl.text.trim() != initialDob && dobCtrl.text.trim().isNotEmpty) {
        request.fields["dob"] = _toApiDate(dobCtrl.text.trim());
      }

      if (selectedGender != initialGender && selectedGender.isNotEmpty) {
        request.fields["gender"] = selectedGender.toUpperCase();
      }

      /// Handle Image Upload
      if (selectedImage != null) {
        File file = selectedImage!;

        // Compress image if >2MB
        int fileSize = await file.length();
        if (fileSize > 2 * 1024 * 1024) {
          Get.snackbar(
            "Compressing Image...",
            "Large image will be compressed automatically",
            snackPosition: SnackPosition.TOP,
            duration: Duration(seconds: 2),
          );

          final compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            "${file.parent.path}/temp_${file.uri.pathSegments.last}",
            quality: 70, // adjust quality as needed
          );

          if (compressedFile != null) {
            file = compressedFile as File;
            fileSize = await file.length();
          }
        }

        // Backend rejects restaurant profile images above 2 MB.
        if (fileSize > 2 * 1024 * 1024) {
          Get.snackbar(
            "Image Too Large 🚫",
            "Compressed image is still above 2 MB. Please choose a smaller image.",
            snackPosition: SnackPosition.TOP,
          );
          return;
        }

        final mimeType = lookupMimeType(file.path) ?? "image/jpeg";
        final mimeSplit = mimeType.split("/");

        request.files.add(
          await http.MultipartFile.fromPath(
            "profilePic",
            file.path,
            contentType: http.MediaType(mimeSplit[0], mimeSplit[1]),
          ),
        );
      }

      /// Nothing changed
      if (request.fields.isEmpty && request.files.isEmpty) {
        Get.snackbar("No Changes", "Nothing to update");
        return;
      }

      /// Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      /// Handle HTML responses gracefully
      if (response.headers['content-type']?.contains('application/json') ?? false) {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200 && data["success"] == true) {
          Get.snackbar("Success ✅", data["message"]);

          initialName = nameCtrl.text.trim();
          initialEmail = emailCtrl.text.trim();
          initialDob = dobCtrl.text.trim();
          initialGender = selectedGender;

          final profilePic = data["profile"]["profilePic"];
          profileImageUrl = profilePic;
          selectedImage = null;
          print("Updated Profile Pic URL: $profilePic");
        } else {
          Get.snackbar("Error", data["message"] ?? "Update failed");
        }
      } else {
        final responseBody = response.body.trim();
        Get.snackbar(
          "Upload Failed",
          responseBody.isNotEmpty
              ? responseBody
              : "Image is too large for the server or server returned an error.",
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print("UPDATE ERROR: $e");
      Get.snackbar("Error", "Something went wrong");
    }
  }
  /// ================= EDIT POPUP =================
  void _showEditProfilePopup() {
    final tempName = TextEditingController(text: nameCtrl.text);
    final tempEmail = TextEditingController(text: emailCtrl.text);
    final tempDob = TextEditingController(text: dobCtrl.text);
    String tempGender = selectedGender;

    ImageProvider? imageProvider;
    if (selectedImage != null) {
      imageProvider = FileImage(selectedImage!);
    } else if (profileImageUrl != null) {
      imageProvider = NetworkImage(profileImageUrl!);
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// DRAG HANDLE
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 18),

              /// TITLE
              const Text(
                "Edit Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 22),

              /// PROFILE IMAGE WITH RING + EDIT ICON
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ColorConstants.success,
                          ColorConstants.success.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 36)
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedImage = File(picked.path);
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              /// NAME FIELD
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Name",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _inputField(controller: tempName, hint: "Full name"),

              const SizedBox(height: 18),

              /// EMAIL FIELD
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _inputField(
                controller: tempEmail,
                hint: "abc@gmail.com",
                keyboard: TextInputType.emailAddress,
              ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Date of Birth",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: tempDob,
                readOnly: true,
                onTap: () async {
                  final pickedDate = await _pickDate(
                    initialDate: _parseDisplayDate(tempDob.text),
                  );
                  if (pickedDate == null) {
                    return;
                  }
                  tempDob.text = _formatDate(pickedDate.toIso8601String());
                },
                decoration: InputDecoration(
                  hintText: "DD/MM/YYYY",
                  filled: true,
                  fillColor: const Color(0xFFF7F9FC),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Gender",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              StatefulBuilder(
                builder: (context, setModalState) {
                  return DropdownButtonFormField<String>(
                    value: tempGender.isEmpty ? null : tempGender,
                    items: const [
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempGender = value ?? '';
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Select gender",
                      filled: true,
                      fillColor: const Color(0xFFF7F9FC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              /// SAVE BUTTON (REAL CTA)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.success,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () {
                    if (tempName.text.trim().isEmpty) {
                      Get.snackbar("Error", "Name is required");
                      return;
                    }

                    if (tempName.text.trim() == initialName &&
                        tempEmail.text.trim() == initialEmail &&
                        tempDob.text.trim() == initialDob &&
                        tempGender == initialGender &&
                        selectedImage == null) {
                      Get.snackbar("No Changes", "Nothing to update");
                      return;
                    }

                    nameCtrl.text = tempName.text.trim();
                    emailCtrl.text = tempEmail.text.trim();
                    dobCtrl.text = tempDob.text.trim();
                    selectedGender = tempGender;

                    Get.back();
                    updateProfile();
                  },
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (selectedImage != null) {
      imageProvider = FileImage(selectedImage!);
    } else if (profileImageUrl != null) {
      imageProvider = NetworkImage(profileImageUrl!);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(title: const Text("Profile"), centerTitle: true),
      body: isLoading
          ? _buildShimmer()
          : RefreshIndicator(
        color: ColorConstants.success,
        onRefresh: () async {
          setState(() {
            isLoading = true;
          });
          await fetchProfile();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // ⭐ THIS FIX
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _profileHeader(imageProvider),
              const SizedBox(height: 24),
              _statusCard(),
              const SizedBox(height: 20),
              _infoTile(Icons.person_outline, "Name", _fallbackValue(nameCtrl.text)),
              _infoTile(Icons.cake_outlined, "DOB", _fallbackValue(dobCtrl.text)),
              _infoTile(
                Icons.wc_outlined,
                "Gender",
                _fallbackValue(selectedGender),
              ),
              _infoTile(Icons.phone, "Phone", phoneCtrl.text),
              _infoTile(Icons.email, "Email", emailCtrl.text),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit Profile"),
                trailing:
                const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showEditProfilePopup,
              ),
            ],
          ),
        ),
      ),

    );
  }

  /// ================= UI HELPERS =================
  Widget _profileHeader(ImageProvider? imageProvider) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            InkWell(
              onTap: imageProvider == null
                  ? null
                  : () {
                      showSimpleDialog(context, profileImageUrl!);
                      print("Hi ${nameCtrl.text}");
                    },
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
            ),

            /// 🟢 Active / 🔴 Inactive
            Container(
              margin: const EdgeInsets.only(right: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                isActive ? "ACTIVE" : "INACTIVE",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          _fallbackValue(nameCtrl.text),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        Text(
          _fallbackValue(emailCtrl.text),
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _statusCard() {
    Color color;
    IconData icon;

    switch (verificationStatus) {
      case "APPROVED":
        color = Colors.green;
        icon = Icons.verified;
        break;
      case "REJECTED":
        color = Colors.red;
        icon = Icons.cancel;
        break;
      case "NOT_SUBMITTED":
        color = Colors.blueGrey;
        icon = Icons.assignment_late_outlined;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_top;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              "Verification: $verificationStatus",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 15,
              ),
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Center(
      child:Column(
        children: [
          const SizedBox(height: 40),
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: const CircleAvatar(radius: 60),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: ColorConstants.success),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  String _fallbackValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not added yet';
    }
    return value.trim();
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return '';
    }

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  String _toApiDate(String displayDate) {
    final parts = displayDate.split('/');
    if (parts.length != 3) {
      return displayDate;
    }
    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];
    return '$year-$month-$day';
  }

  String _displayGender(dynamic value) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    switch (raw) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
        return 'Other';
      default:
        return '';
    }
  }

  DateTime? _parseDisplayDate(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    final parts = value.split('/');
    if (parts.length != 3) {
      return null;
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  Future<DateTime?> _pickDate({DateTime? initialDate}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
  }


  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void showSimpleDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              /// Image Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, __, ___) => SizedBox(
                      height: 300,
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              /// CLOSE ICON
              Positioned(
                top: 10,
                right: 10,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),

              /// EDIT ICON (ONLY IMAGE CHANGE)
              Positioned(
                bottom: 14,
                right: 14,
                child: InkWell(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );

                    if (picked != null) {
                      setState(() {
                        selectedImage = File(picked.path);
                      });

                      Navigator.pop(context); // close dialog
                      updateProfile(); // upload image
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
