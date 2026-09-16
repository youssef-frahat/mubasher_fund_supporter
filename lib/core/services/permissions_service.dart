import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

import '../language/language_cubit.dart';

class PermissionsService {
  /// Request notification permissions
  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    
    if (status.isGranted) return true;
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context, context.isArabic ? 'الإشعارات' : 'Notifications');
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
      if (context.mounted) _showSettingsDialog(context, context.isArabic ? 'الصور' : 'Photos');
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
        title: Text('${context.tr('permissionRequired')} ($permissionName)'),
        content: Text(
          context.isArabic
              ? 'يرجى تفعيل صلاحية $permissionName من إعدادات الجهاز للمتابعة.'
              : 'Please enable $permissionName in your device settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: Text(context.tr('openSettings')),
          ),
        ],
      ),
    );
  }
}
