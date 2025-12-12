import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseStatus {
  const LicenseStatus({this.key, this.registeredAt, this.expiry});

  final String? key;
  final DateTime? registeredAt;
  final DateTime? expiry;

  bool get hasKey => (key != null && key!.trim().isNotEmpty);
  bool get hasExpiry => expiry != null;
  bool get isExpired => hasExpiry ? DateTime.now().isAfter(expiry!) : false;
  bool get isActive => hasKey && hasExpiry && !isExpired;
  int get daysRemaining {
    if (!hasExpiry) return 0;
    return expiry!.difference(DateTime.now()).inDays;
  }
}

class LicenseService {
  LicenseService._();
  static final LicenseService instance = LicenseService._();

  // 12 random, single-use license keys (format: 4-4-4-4 alphanum, case-insensitive)
  static const List<String> validKeys = [
    'K9QF-7T3M-ZX82-LN5P',
    'R4VD-1J8H-PQ6T-3XNA',
    'M7CL-9W2K-HD5Q-V8RP',
    'T2NB-X6J4-8QKV-L1DM',
    'H5ZR-3PQN-7M8L-VA2T',
    'Q8TJ-4L9V-N2RD-X7KM',
    'P1MX-6KQ7-T9HL-3VDR',
    'D6VN-2R5T-XQ14-M9KP',
    'X3HL-8N7Q-P6JD-1RTM',
    'N9KQ-5V2L-RT8X-4JHD',
    'V1RP-7X6D-L3MQ-9T2N',
    'L8DM-4H1T-K7VN-Q6XR',
  ];

  static String normalize(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  static final Set<String> _validNormalized = validKeys.map(normalize).toSet();

  // Special test keys: single-use, custom validity (months), do not count towards the 12-license quota
  static const Map<String, int> _specialKeysMonths = {
    // normalized form (no dashes, uppercase) : months
    'PHARMA-TEST-3M-2025': 3,
    'PHARMAXY-LIFE-2025': 9999, // Clé à vie
  };

  // Preference keys
  static const _keyActive = 'license_key';
  static const _keyRegisteredAt = 'license_registered_at';
  static const _keyExpiry = 'license_expiry';
  static const _keyUsedList = 'license_used_keys'; // string list (normalized)

  // SupAdmin secret: fixed at build-time, not changeable in app
  static const String _supAdminSecret = String.fromEnvironment(
    'SUPADMIN_PASSWORD',
    defaultValue: 'PHARMAXY#SupAdmin2025!',
  );

  // Reactive notifier for UI to gate features
  ValueListenable<bool> get activeNotifier => _licenseNotifier;

  Future<LicenseStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyActive);
    final regStr = prefs.getString(_keyRegisteredAt);
    final expiryStr = prefs.getString(_keyExpiry);
    DateTime? regAt;
    DateTime? expiry;
    if (regStr != null && regStr.isNotEmpty) {
      try {
        regAt = DateTime.parse(regStr);
      } catch (_) {}
    }
    if (expiryStr != null && expiryStr.isNotEmpty) {
      try {
        expiry = DateTime.parse(expiryStr);
      } catch (_) {}
    }
    return LicenseStatus(key: key, registeredAt: regAt, expiry: expiry);
  }

  Future<bool> hasActive() async {
    final st = await getStatus();
    return st.isActive;
  }

  Future<void> saveLicense({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = normalize(key);
    final used = prefs.getStringList(_keyUsedList) ?? <String>[];
    final isStandard = _validNormalized.contains(normalized);
    final isSpecial = _specialKeysMonths.containsKey(normalized);
    final alreadyUsed = used.contains(normalized);
    if (!(isStandard || isSpecial) || alreadyUsed) {
      throw Exception('Clé invalide ou déjà utilisée');
    }
    final now = DateTime.now();
    final months = isStandard ? 12 : (_specialKeysMonths[normalized] ?? 12);
    final expiry = DateTime(now.year, now.month + months, now.day, 23, 59, 59);
    await prefs.setString(_keyActive, normalized);
    await prefs.setString(_keyRegisteredAt, now.toIso8601String());
    await prefs.setString(_keyExpiry, expiry.toIso8601String());
    await prefs.setStringList(_keyUsedList, [...used, normalized]);
    await refreshActive();
  }

  Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyActive);
    await prefs.remove(_keyRegisteredAt);
    await prefs.remove(_keyExpiry);
    // Important: do NOT remove from used list; single-use remains enforced
    await refreshActive();
  }

  Future<void> refreshActive() async {
    final st = await getStatus();
    (_licenseNotifier as _LicenseActiveNotifier).update(st.isActive);
  }

  Future<bool> allKeysUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final used = (prefs.getStringList(_keyUsedList) ?? <String>[]).toSet();
    return _validNormalized.difference(used).isEmpty;
  }

  static final _LicenseActiveNotifier _licenseNotifier =
      _LicenseActiveNotifier();

  Future<bool> verifySupAdmin(String password) async {
    return constantTimeEquals(password, _supAdminSecret);
  }

  bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

class _LicenseActiveNotifier extends ValueNotifier<bool>
    implements ValueListenable<bool> {
  _LicenseActiveNotifier() : super(false);
  void update(bool v) {
    if (value != v) value = v;
  }
}
