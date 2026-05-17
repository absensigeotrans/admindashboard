import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserEmail = 'saved_email';
  static const String _keyUserPassword = 'saved_password';

  Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> hasEnrolledBiometrics() async {
    final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
    return availableBiometrics.isNotEmpty;
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Gunakan sidik jari atau Face ID untuk masuk ke GeoAttend PTK',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error Biometric: $e');
      return false;
    }
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserPassword, value: password);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyBiometricEnabled);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserPassword);
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    final isEnabled = await _storage.read(key: _keyBiometricEnabled);

    if (isEnabled != 'true') return {'email': null, 'password': null};

    return {
      'email': await _storage.read(key: _keyUserEmail),
      'password': await _storage.read(key: _keyUserPassword),
    };
  }

  Future<bool> isFeatureEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }
}
