// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get_core/src/get_main.dart';
// import 'package:get/get_instance/src/extension_instance.dart';
// import 'package:get/get_navigation/src/extension_navigation.dart';
// import 'package:get/get_navigation/src/root/get_material_app.dart';
// import 'package:hungzo_app/screens/auth/create_account.dart';
// import 'package:hungzo_app/screens/auth/login/login_screen.dart';
// import 'package:hungzo_app/screens/auth/login/otp_verification.dart';
// import 'package:hungzo_app/screens/home_view.dart';
// import 'package:hungzo_app/screens/splash/splash_screen.dart';
// import 'package:hungzo_app/utils/ColorConstants.dart';
//
// import 'bindings/app_binding.dart';
// import 'bindings/home_binding.dart';
// import 'controllers/order_controller.dart';
// import 'firebase_login_screen.dart';
// import 'firebase_options.dart';
//
// void main() async {
//   Get.put(OrderController(), permanent: true); // 🔥 ONLY ONCE
//
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }
//
//
// // Using ValueNotifier to dynamically switch theme
// class MyApp extends StatefulWidget {
//   const MyApp({super.key});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
// final GlobalKey<NavigatorState> rootNavigatorKey =
// GlobalKey<NavigatorState>();
//
//
// class _MyAppState extends State<MyApp> {
//   final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);
//
//   void _toggleTheme() {
//     _themeNotifier.value = _themeNotifier.value == ThemeMode.light
//         ? ThemeMode.dark
//         : ThemeMode.light;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: _themeNotifier,
//       builder: (context, currentTheme, _) {
//         return GetMaterialApp(
//           initialBinding: AppBinding(),
//
//           navigatorKey: rootNavigatorKey, // ✅ IMPORTANT
//           title: 'HungZo',
//           debugShowCheckedModeBanner: false,
//
//           theme: ThemeData(
//             brightness: Brightness.light,
//             primaryColor: ColorConstants.primary,
//             scaffoldBackgroundColor: ColorConstants.scaffoldBackground,
//           ),
//
//           darkTheme: ThemeData(
//             brightness: Brightness.dark,
//             primaryColor: ColorConstants.primaryDark,
//             scaffoldBackgroundColor:
//             ColorConstants.primaryDark.withOpacity(0.9),
//           ),
//
//           themeMode: currentTheme,
//           home: SplashScreen(),
//         );
//       },
//     );
//   }
// }

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:hungzo_app/screens/splash/splash_screen.dart';
import 'package:hungzo_app/utils/ColorConstants.dart';

import 'bindings/app_binding.dart';
import 'controllers/order_controller.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
  );

  Get.put(OrderController(), permanent: true); // 🔥 ONLY ONCE

  runApp(const MyApp());
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// Using ValueNotifier to dynamically switch theme
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeNotifier =
      ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, currentTheme, _) {
        return GetMaterialApp(
          // initialBinding: HomeBinding(),
          initialBinding: AppBinding(),
          // navigatorKey: Get.key,
          navigatorKey: rootNavigatorKey, // ✅ IMPORTANT

          title: 'HungZo',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: ColorConstants.primary,
            scaffoldBackgroundColor: ColorConstants.scaffoldBackground,
            colorScheme: ColorScheme.light(
              primary: ColorConstants.primary,
              secondary: ColorConstants.accent,
              surface: ColorConstants.scaffoldBackground,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: ColorConstants.primaryDark,
            scaffoldBackgroundColor:
                ColorConstants.primaryDark.withValues(alpha: 0.9),
            colorScheme: ColorScheme.dark(
              primary: ColorConstants.primaryDark,
              secondary: ColorConstants.accent,
              surface: ColorConstants.primaryDark.withValues(alpha: 0.9),
            ),
          ),
          themeMode: currentTheme,
          home: SplashScreen(),
        );
      },
    );
  }
}
