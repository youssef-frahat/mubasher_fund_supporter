import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static bool isCurrentlyAuthenticating = false;
  static DateTime? lastUnlockedTime;

  /// Check if device supports Biometric Authentication (Fingerprint / Face ID)
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint('Error checking biometrics availability: $e');
      return false;
    }
  }

  /// Get list of available biometrics (Face ID, Fingerprint, etc.)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Trigger Biometric Authentication Prompt
  static Future<bool> authenticateUser(BuildContext context, {String? localizedReason}) async {
    if (isCurrentlyAuthenticating) return false;
    isCurrentlyAuthenticating = true;

    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الجهاز لا يدعم البصمة أو لم يتم إعداد بصمة في إعدادات الهاتف.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }

      await HapticFeedback.mediumImpact();

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason ?? 'يرجى تأكيد بصمة الأصبع أو الوجه لتأمين الحساب',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuthenticate) {
        lastUnlockedTime = DateTime.now();
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Biometrics PlatformException: ${e.code} - ${e.message}');
      if (context.mounted) {
        String msg = 'حدث خطأ أثناء التحقق من البصمة.';
        if (e.code == 'NotEnrolled') {
          msg = 'لم يتم تسجيل أي بصمة في إعدادات الهاتف. يرجى إضافة بصمة أولاً.';
        } else if (e.code == 'NotAvailable') {
          msg = 'خاصية البصمة غير متاحة حالياً على الهاتف.';
        } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
          msg = 'تم قفل البصمة لكثرة المحاولات الخاطئة. يرجى فتح الهاتف بكلمة المرور أولاً.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
      return false;
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    } finally {
      isCurrentlyAuthenticating = false;
    }
  }
}
