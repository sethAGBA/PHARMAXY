import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import 'local_database_service.dart';

/// Minimal authentication helper inspired by the School Manager login flow.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Future<AppUser?> tryAutoLogin() async {
    final remembered = await getRememberedIdentifier();
    if (remembered == null) return null;
    final user = await _findUser(remembered);
    if (user == null || !user.isActive) return null;
    _currentUser = user;
    return _currentUser;
  }

  Future<AppUser?> login(
    String identifier,
    String password, {
    bool rememberMe = false,
  }) async {
    final user = await _findUser(identifier);
    if (user == null) return null;
    if (!user.isActive || user.password != password) return null;

    final updated = user.copyWith(lastLogin: DateTime.now());
    await LocalDatabaseService.instance.db.update(
      'utilisateurs',
      {'last_login': updated.lastLogin.toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    _currentUser = updated;
    await _persistRememberPreference(identifier, rememberMe);
    return updated;
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  Future<String?> getRememberedIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    if (!remember) return null;
    return prefs.getString('remember_identifier');
  }

  Future<void> _persistRememberPreference(
    String identifier,
    bool rememberMe,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', rememberMe);
    if (rememberMe) {
      await prefs.setString('remember_identifier', identifier);
    } else {
      await prefs.remove('remember_identifier');
    }
  }

  Future<AppUser?> _findUser(String identifier) async {
    final rows = await LocalDatabaseService.instance.db.query(
      'utilisateurs',
      where: 'LOWER(email) = ? OR LOWER(id) = ?',
      whereArgs: [identifier.toLowerCase(), identifier.toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  String generateTwoFactorSecret() {
    return OTP.randomSecret();
  }

  String buildTwoFactorProvisioningUri({
    required String account,
    required String secret,
    String issuer = 'PHARMAXY',
  }) {
    final encodedIssuer = Uri.encodeComponent(issuer);
    final encodedAccount = Uri.encodeComponent('$issuer:$account');
    return 'otpauth://totp/$encodedIssuer:$encodedAccount'
        '?secret=$secret&issuer=$encodedIssuer&algorithm=SHA1&digits=6&period=30';
  }

  bool verifyTwoFactorCode(String secret, String code) {
    final normalized = code.replaceAll(RegExp(r'[^0-9]'), '');
    if (normalized.length < 6) return false;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    for (int offset = -1; offset <= 1; offset++) {
      final value = OTP.generateTOTPCodeString(
        secret,
        nowMillis + (offset * 30000),
        interval: 30,
        length: 6,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (value == normalized) return true;
    }
    return false;
  }

  bool verifyUserTwoFactor(AppUser user, String code) {
    final secret = user.totpSecret;
    if (secret == null || secret.isEmpty) return false;
    return verifyTwoFactorCode(secret, code);
  }
}
