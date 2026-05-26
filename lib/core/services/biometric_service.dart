import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Outcome of a biometric prompt. [success] is true only on a confirmed match;
/// [error] carries a user-facing message for *genuine* failures (lockout, no
/// hardware/enrollment) and is null for success or a plain user cancel — so the
/// caller can stay silent on cancel but surface real problems instead of a
/// dead, no-op button.
class BiometricResult {
  final bool success;
  final String? error;
  const BiometricResult(this.success, [this.error]);
}

/// Thin wrapper over `local_auth` for fingerprint / Face ID sign-in.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// True only when the device can perform a biometric check *right now* —
  /// hardware present AND at least one biometric enrolled. (`&&`, not `||`, so a
  /// device with a sensor but nothing enrolled correctly reports unavailable.)
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// The enrolled biometric kinds, used to label the button (Face ID vs print).
  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Prompts the OS biometric sheet. `biometricOnly: true` — the device passcode
  /// is NOT accepted as a fallback, so the stored password stays gated behind
  /// biometric identity rather than the (often shared) device PIN.
  Future<BiometricResult> authenticate({String reason = 'Authenticate to sign in'}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      // `ok == false` with no exception ⇒ user cancelled or scan failed; stay quiet.
      return BiometricResult(ok);
    } on PlatformException catch (e) {
      final message = switch (e.code) {
        auth_error.lockedOut ||
        auth_error.permanentlyLockedOut =>
          'Biometrics are temporarily locked. Sign in with your password.',
        auth_error.notEnrolled ||
        auth_error.notAvailable ||
        auth_error.passcodeNotSet =>
          "Biometric sign-in isn't set up on this device.",
        _ => 'Biometric sign-in failed. Sign in with your password.',
      };
      return BiometricResult(false, message);
    } catch (_) {
      return const BiometricResult(
          false, 'Biometric sign-in failed. Sign in with your password.');
    }
  }
}
