class Order {
  final String? id;
  final String? userId;
  final String? labourId;
  final String? title;
  final String? description;
  final String? location;
  final DateTime? scheduledAt;
  final double? totalAmount;
  final String? currency;
  final String? orderStatus;
  final DateTime? createdAt;

  Order({
    this.id,
    this.userId,
    this.labourId,
    this.title,
    this.description,
    this.location,
    this.scheduledAt,
    this.totalAmount,
    this.currency,
    this.orderStatus,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      labourId: json['labour_id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      scheduledAt: json['scheduled_at'] != null ? DateTime.tryParse(json['scheduled_at']) : null,
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : null,
      currency: json['currency'],
      orderStatus: json['order_status'],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'labour_id': labourId,
      'title': title,
      'description': description,
      'location': location,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'total_amount': totalAmount,
      'currency': currency,
      'order_status': orderStatus,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

