import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../utils/ColorConstants.dart';
import 'about_us_screen.dart';
import 'address_book_screen.dart';
import 'edit_profile_screen.dart';
import 'my_orders_screen.dart';
import 'splash/splash_screen.dart';
import 'wallet_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  AccountSettingsScreen({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoggedIn = authController.isLoggedIn.value;

      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Account",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: authController.isSessionReady.value
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderCard(isLoggedIn),
                    const SizedBox(height: 24),
                    const Text(
                      "Account Settings",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.success,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _settingsTile(
                      icon: Icons.person_outline,
                      title: "Edit Profile",
                      subtitle:
                          isLoggedIn ? null : "Login required to update profile",
                      onTap: () => _openProtected(
                        title: 'Login to edit profile',
                        message:
                            'Please log in to manage your profile details.',
                        screen: EditProfileScreen(),
                      ),
                    ),
                    _settingsTile(
                      icon: Icons.inventory_2_outlined,
                      title: "My Orders",
                      subtitle:
                          isLoggedIn ? null : "Login required to view orders",
                      onTap: () => _openProtected(
                        title: 'Login to view orders',
                        message:
                            'Please log in to see your order history and tracking updates.',
                        screen: MyOrdersScreen(),
                      ),
                    ),
                    _settingsTile(
                      icon: Icons.location_on_outlined,
                      title: "Address Book",
                      subtitle:
                          isLoggedIn ? null : "Login required to manage addresses",
                      onTap: () => authController
                          .ensureAuthenticated(
                            title: 'Login to manage addresses',
                            message:
                                'Please log in to add or manage your saved addresses.',
                          )
                          .then((didLogin) {
                            if (didLogin) {
                              Get.to(() => const AddressBookScreen());
                            }
                          }),
                    ),
                    _settingsTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Wallet",
                      subtitle:
                          isLoggedIn ? null : "Login required to access wallet",
                      onTap: () => _openProtected(
                        title: 'Login to access wallet',
                        message:
                            'Please log in to check balance and wallet transactions.',
                        screen: WalletScreen(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "General Settings",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ColorConstants.success,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _settingsTile(
                      icon: Icons.info_outline,
                      title: "About us",
                      onTap: () => Get.to(() => const AboutUsScreen()),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isLoggedIn ? Colors.red : ColorConstants.success,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: authController.isLoading.value
                            ? null
                            : () {
                                if (isLoggedIn) {
                                  _showLogoutDialog(context);
                                } else {
                                  authController.ensureAuthenticated(
                                    title: 'Login or sign up',
                                    message:
                                        'Please log in to use saved orders, cart, wallet, and profile features.',
                                  );
                                }
                              },
                        child: Text(
                          isLoggedIn ? "Log Out" : "Login or Sign Up",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      );
    });
  }

  Widget _buildHeaderCard(bool isLoggedIn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF16AB88),
            Color(0xFF0D8D70),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLoggedIn ? 'Welcome back' : 'Explore as a guest',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLoggedIn
                ? 'Your orders, wallet, and profile tools are ready.'
                : 'You can browse the app freely. We will ask you to log in only when an action needs your account.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.black),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Future<void> _openProtected({
    required String title,
    required String message,
    required Widget screen,
  }) async {
    final didLogin = await authController.ensureAuthenticated(
      title: title,
      message: message,
    );

    if (didLogin) {
      Get.to(() => screen);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                await authController.logout();
                Get.offAll(() => const SplashScreen());
              } catch (e) {
                debugPrint("Logout error: $e");
              }
            },
            child: const Text(
              "Log Out",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
