import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsService {
  /// Request notification permissions
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Notifications');
      return false;
    }

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Request photo library permissions
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    final status = await Permission.photos.status;
    
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, 'Photos');
      return false;
    }

    final result = await Permission.photos.request();
    return result.isGranted;
  }

  /// Helper to show a dialog directing the user to app settings
  static void _showSettingsDialog(BuildContext context, String permissionName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text('Please enable $permissionName in your device settings to use this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
