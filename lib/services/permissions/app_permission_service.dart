import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../screens/permissions/permission_dialog.dart';
import '../../utils/ImageConstant.dart';

enum PermissionRequestOutcome {
  granted,
  denied,
  deferred,
  blocked,
  serviceDisabled,
}

class AppPermissionService {
  static Future<PermissionRequestOutcome> ensureNotificationAccess(
    BuildContext context,
  ) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return PermissionRequestOutcome.granted;
    if (!context.mounted) return PermissionRequestOutcome.denied;

    if (status.isPermanentlyDenied || status.isRestricted) {
      return _showSettingsDialog(
        context: context,
        title: "Turn on notifications",
        message:
            "Enable notifications in Settings to receive order updates and important reminders.",
        imageAsset: ImageConstant.notification,
        confirmText: "Open Settings",
      );
    }

    final shouldContinue = await _showPrePrompt(
      context: context,
      title: "Stay updated",
      message:
          "Turn on notifications so we can let you know about order status, delivery updates, and important alerts.",
      imageAsset: ImageConstant.notification,
      confirmText: "Continue",
      cancelText: "Not now",
    );

    if (!shouldContinue) return PermissionRequestOutcome.deferred;

    final result = await Permission.notification.request();
    if (result.isGranted) return PermissionRequestOutcome.granted;
    if (!context.mounted) return PermissionRequestOutcome.denied;

    if (result.isPermanentlyDenied || result.isRestricted) {
      return _showSettingsDialog(
        context: context,
        title: "Notifications are blocked",
        message:
            "You can still use the app, but you may miss delivery updates until notifications are enabled in Settings.",
        imageAsset: ImageConstant.notification,
        confirmText: "Open Settings",
      );
    }

    return PermissionRequestOutcome.denied;
  }

  static Future<PermissionRequestOutcome> ensureLocationAccess(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return PermissionRequestOutcome.serviceDisabled;
      return _showLocationServicesDialog(context);
    }

    final status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      return PermissionRequestOutcome.granted;
    }
    if (!context.mounted) return PermissionRequestOutcome.denied;

    if (status.isPermanentlyDenied || status.isRestricted) {
      return _showSettingsDialog(
        context: context,
        title: "Location access is blocked",
        message:
            "Enable location in Settings to use current address, map pinning, and serviceability checks.",
        imageAsset: ImageConstant.location,
        confirmText: "Open Settings",
      );
    }

    final shouldContinue = await _showPrePrompt(
      context: context,
      title: title,
      message: message,
      imageAsset: ImageConstant.location,
      confirmText: "Continue",
      cancelText: "Not now",
    );

    if (!shouldContinue) return PermissionRequestOutcome.deferred;

    final result = await Permission.location.request();
    if (result.isGranted || result.isLimited) {
      return PermissionRequestOutcome.granted;
    }
    if (!context.mounted) return PermissionRequestOutcome.denied;

    if (result.isPermanentlyDenied || result.isRestricted) {
      return _showSettingsDialog(
        context: context,
        title: "Location access is blocked",
        message:
            "Open Settings to allow location access when you want to use your current address.",
        imageAsset: ImageConstant.location,
        confirmText: "Open Settings",
      );
    }

    return PermissionRequestOutcome.denied;
  }

  static Future<bool> _showPrePrompt({
    required BuildContext context,
    required String title,
    required String message,
    required String imageAsset,
    required String confirmText,
    required String cancelText,
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PermissionDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          imageAsset: imageAsset,
          onConfirm: () => Navigator.of(dialogContext).pop(true),
          onCancel: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );

    return result ?? false;
  }

  static Future<PermissionRequestOutcome> _showSettingsDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String imageAsset,
    required String confirmText,
  }) async {
    final openSettings = await _showPrePrompt(
      context: context,
      title: title,
      message: message,
      imageAsset: imageAsset,
      confirmText: confirmText,
      cancelText: "Not now",
    );

    if (!openSettings) return PermissionRequestOutcome.blocked;

    await openAppSettings();
    return PermissionRequestOutcome.blocked;
  }

  static Future<PermissionRequestOutcome> _showLocationServicesDialog(
    BuildContext context,
  ) async {
    final openSettings = await _showPrePrompt(
      context: context,
      title: "Turn on location services",
      message:
          "Location services are off. Turn them on to detect your current address and check if delivery is available.",
      imageAsset: ImageConstant.location,
      confirmText: "Open Settings",
      cancelText: "Not now",
    );

    if (!openSettings) return PermissionRequestOutcome.serviceDisabled;

    await Geolocator.openLocationSettings();
    return PermissionRequestOutcome.serviceDisabled;
  }
}
