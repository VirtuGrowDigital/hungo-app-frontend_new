//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class UserModel {
//   final String uid;
//   final String phone;
//   final String fullName;
//   final String restaurantName;
//   final String restaurantAddress;
//   final String city;
//   final String state;
//   final String pincode;
//   final String gstNumber;
//   final String fssaiLicenseNumber;
//   final String email;
//   final String profilePhoto;
//   final String role;
//   final String fcmToken;
//   final DateTime createdAt;
//
//   /// OPTIONAL / FUTURE FIELDS
//   final bool isProfileCompleted;
//   final bool isActive;
//
//   const UserModel({
//     required this.uid,
//     required this.phone,
//     required this.fullName,
//     required this.restaurantName,
//     required this.restaurantAddress,
//     required this.city,
//     required this.state,
//     required this.pincode,
//     required this.gstNumber,
//     required this.fssaiLicenseNumber,
//     required this.email,
//     required this.profilePhoto,
//     required this.role,
//     required this.fcmToken,
//     required this.createdAt,
//     required this.isProfileCompleted,
//     required this.isActive,
//   });
//
//   /// ================= FROM FIREBASE =================
//   factory UserModel.fromMap(Map<String, dynamic> map) {
//     return UserModel(
//       uid: map['uid'] ?? '',
//       phone: map['phone'] ?? '',
//       fullName: map['fullName'] ?? '',
//       restaurantName: map['restaurantName'] ?? '',
//       restaurantAddress: map['restaurantAddress'] ?? '',
//       city: map['city'] ?? '',
//       state: map['state'] ?? '',
//       pincode: map['pincode'] ?? '',
//       gstNumber: map['gstNumber'] ?? '',
//       fssaiLicenseNumber: map['fssaiLicenseNumber'] ?? '',
//       email: map['email'] ?? '',
//       profilePhoto: map['profilePhoto'] ?? '',
//       role: map['role'] ?? 'user',
//       fcmToken: map['fcmToken'] ?? '',
//       createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
//           DateTime.now(),
//       isProfileCompleted: map['isProfileCompleted'] ?? false,
//       isActive: map['isActive'] ?? true,
//     );
//   }
//
//   /// ================= TO FIREBASE =================
//   Map<String, dynamic> toMap() {
//     return {
//       'uid': uid,
//       'phone': phone,
//       'fullName': fullName,
//       'restaurantName': restaurantName,
//       'restaurantAddress': restaurantAddress,
//       'city': city,
//       'state': state,
//       'pincode': pincode,
//       'gstNumber': gstNumber,
//       'fssaiLicenseNumber': fssaiLicenseNumber,
//       'email': email,
//       'profilePhoto': profilePhoto,
//       'role': role,
//       'fcmToken': fcmToken,
//       'createdAt': Timestamp.fromDate(createdAt),
//       'isProfileCompleted': isProfileCompleted,
//       'isActive': isActive,
//     };
//   }
//
//   /// ================= COPY WITH =================
//   UserModel copyWith({
//     String? uid,
//     String? phone,
//     String? fullName,
//     String? restaurantName,
//     String? restaurantAddress,
//     String? city,
//     String? state,
//     String? pincode,
//     String? gstNumber,
//     String? fssaiLicenseNumber,
//     String? email,
//     String? profilePhoto,
//     String? role,
//     String? fcmToken,
//     DateTime? createdAt,
//     bool? isProfileCompleted,
//     bool? isActive,
//   }) {
//     return UserModel(
//       uid: uid ?? this.uid,
//       phone: phone ?? this.phone,
//       fullName: fullName ?? this.fullName,
//       restaurantName: restaurantName ?? this.restaurantName,
//       restaurantAddress:
//       restaurantAddress ?? this.restaurantAddress,
//       city: city ?? this.city,
//       state: state ?? this.state,
//       pincode: pincode ?? this.pincode,
//       gstNumber: gstNumber ?? this.gstNumber,
//       fssaiLicenseNumber:
//       fssaiLicenseNumber ?? this.fssaiLicenseNumber,
//       email: email ?? this.email,
//       profilePhoto: profilePhoto ?? this.profilePhoto,
//       role: role ?? this.role,
//       fcmToken: fcmToken ?? this.fcmToken,
//       createdAt: createdAt ?? this.createdAt,
//       isProfileCompleted:
//       isProfileCompleted ?? this.isProfileCompleted,
//       isActive: isActive ?? this.isActive,
//     );
//   }
// }
