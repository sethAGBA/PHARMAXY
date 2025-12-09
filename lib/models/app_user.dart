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
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

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
    };
  }

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      createdAt: DateTime.parse(map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      lastLogin: DateTime.parse(map['last_login'] as String? ?? DateTime.now().toIso8601String()),
      isActive: (map['is_active'] as int? ?? 0) == 1,
    );
  }
}
