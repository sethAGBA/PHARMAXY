import 'dart:convert';

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    this.twoFactorEnabled = false,
    this.totpSecret,
    this.allowedScreens = const [],
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final bool twoFactorEnabled;
  final String? totpSecret;
  final List<String> allowedScreens;

  AppUser copyWith({
    String? name,
    String? email,
    String? password,
    String? role,
    DateTime? lastLogin,
    bool? isActive,
    bool? twoFactorEnabled,
    String? totpSecret,
    List<String>? allowedScreens,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      totpSecret: totpSecret ?? this.totpSecret,
      allowedScreens: allowedScreens ?? this.allowedScreens,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'two_factor_enabled': twoFactorEnabled ? 1 : 0,
      'totp_secret': totpSecret ?? '',
      'allowed_screens': jsonEncode(allowedScreens),
    };
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    List<String> screens = [];
    final encodedScreens = map['allowed_screens'] as String?;
    if (encodedScreens != null && encodedScreens.isNotEmpty) {
      try {
        final decoded = jsonDecode(encodedScreens) as List<dynamic>;
        screens = decoded.map((e) => e.toString()).toList();
      } catch (_) {
        screens = [];
      }
    }

    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      createdAt: DateTime.parse(
        map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      lastLogin: DateTime.parse(
        map['last_login'] as String? ?? DateTime.now().toIso8601String(),
      ),
      isActive: (map['is_active'] as int? ?? 0) == 1,
      twoFactorEnabled: (map['two_factor_enabled'] as int?) == 1,
      totpSecret: (map['totp_secret'] as String?)?.isEmpty == true
          ? null
          : (map['totp_secret'] as String?),
      allowedScreens: screens,
    );
  }
}
