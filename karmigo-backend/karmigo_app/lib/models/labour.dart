class Labour {
  final String fullName;
  final String email;
  final String? phone;
  final String? skills;
  final double? rating;
  final String? id;
  final DateTime? createdAt;

  Labour({
    required this.fullName,
    required this.email,
    this.phone,
    this.skills,
    this.rating,
    this.id,
    this.createdAt,
  });

  factory Labour.fromJson(Map<String, dynamic> json) {
    return Labour(
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      skills: json['skills'],
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : null,
      id: json['id'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'skills': skills,
      'rating': rating,
      'id': id,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

