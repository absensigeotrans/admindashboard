import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  // Keys for SharedPreferences
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserEmail = 'saved_email';
  static const String _keyUserPassword = 'saved_password';

  /// Cek apakah perangkat mendukung biometric (Hardware ada & Aktif)
  Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  /// Cek apakah ada biometric yang sudah terdaftar (Enrolled)
  Future<bool> hasEnrolledBiometrics() async {
    final List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
    return availableBiometrics.isNotEmpty;
  }

  /// Proses Autentikasi
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

  /// Simpan kredensial (Hanya dipanggil kalau user mengaktifkan toggle biometric di settings)
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserPassword, password);
  }

  /// Hapus kredensial
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBiometricEnabled);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserPassword);
  }

  /// Ambil data login tersimpan
  Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    
    if (!isEnabled) return {'email': null, 'password': null};

    return {
      'email': prefs.getString(_keyUserEmail),
      'password': prefs.getString(_keyUserPassword),
    };
  }

  /// Cek apakah fitur biometric sedang aktif di aplikasi
  Future<bool> isFeatureEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }
}
