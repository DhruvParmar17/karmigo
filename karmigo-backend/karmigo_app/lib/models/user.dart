class User {
  final String email;
  final String? fullName;
  final String? phone;
  final String? id;
  final String? hashedPassword;
  final bool isActive;
  final bool isSuperuser;
  final DateTime? createdAt;

  User({
    required this.email,
    this.fullName,
    this.phone,
    this.id,
    this.hashedPassword,
    this.isActive = true,
    this.isSuperuser = false,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] ?? '',
      fullName: json['full_name'],
      phone: json['phone'],
      id: json['id'],
      hashedPassword: json['hashed_password'],
      isActive: json['is_active'] ?? true,
      isSuperuser: json['is_superuser'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'id': id,
      'hashed_password': hashedPassword,
      'is_active': isActive,
      'is_superuser': isSuperuser,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

