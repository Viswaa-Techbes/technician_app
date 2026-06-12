class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
  });
}

class Service {
  final String id;
  final String name;
  final String category;
  final String description;
  final String longDescription;
  final double price;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> features;

  Service({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.longDescription,
    required this.price,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.features,
  });
}

class CartItem {
  final String id;
  final Service service;
  int quantity;
  DateTime scheduledDate;
  String notes;

  CartItem({
    required this.id,
    required this.service,
    this.quantity = 1,
    required this.scheduledDate,
    this.notes = '',
  });

  double get totalPrice => service.price * quantity;
}

class Booking {
  final String id;
  final String userId;
  final Service service;
  final int quantity;
  final DateTime scheduledDate;
  final String notes;
  final DateTime bookedAt;
  final String status; // pending, confirmed, completed, cancelled
  final double totalAmount;

  Booking({
    required this.id,
    required this.userId,
    required this.service,
    required this.quantity,
    required this.scheduledDate,
    required this.notes,
    required this.bookedAt,
    required this.status,
    required this.totalAmount,
  });
}

class Category {
  final String id;
  final String name;
  final String icon;
  final int serviceCount;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.serviceCount,
  });
}
