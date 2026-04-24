import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String phone;
  final String fullName;
  final String restaurantName;
  final String restaurantAddress;
  final String city;
  final String state;
  final String pincode;
  final String? gstNumber;
  final String? fssaiLicenseNumber;
  final String email;
  final String profilePhoto;
  final String role;
  final String fcmToken;
  final DateTime createdAt;
  final bool isProfileCompleted;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.phone,
    required this.fullName,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.gstNumber,
    required this.fssaiLicenseNumber,
    required this.email,
    required this.profilePhoto,
    required this.role,
    required this.fcmToken,
    required this.createdAt,
    required this.isProfileCompleted,
    required this.isActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      restaurantName: map['restaurantName'] as String? ?? '',
      restaurantAddress: map['restaurantAddress'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      gstNumber: map['gstNumber'] as String?,
      fssaiLicenseNumber: map['fssaiLicenseNumber'] as String?,
      email: map['email'] as String? ?? '',
      profilePhoto: map['profilePhoto'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      fcmToken: map['fcmToken'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isProfileCompleted: map['isProfileCompleted'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'fullName': fullName,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gstNumber': gstNumber,
      'fssaiLicenseNumber': fssaiLicenseNumber,
      'email': email,
      'profilePhoto': profilePhoto,
      'role': role,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'isProfileCompleted': isProfileCompleted,
      'isActive': isActive,
    };
  }
}
