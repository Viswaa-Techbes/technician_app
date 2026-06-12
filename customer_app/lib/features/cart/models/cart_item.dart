class CartItem {
  final String id;
  final String serviceSlug;
  final String serviceName;
  final String? categoryId;
  final String subcategoryId;
  final Map<String, dynamic> input;
  final Map<String, dynamic> price;
  final String? notes;

  CartItem({
    required this.id,
    required this.serviceSlug,
    required this.serviceName,
    this.categoryId,
    required this.subcategoryId,
    required this.input,
    required this.price,
    this.notes,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      serviceSlug: json['serviceSlug'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      subcategoryId: json['subcategoryId'] as String? ?? '',
      input: json['input'] as Map<String, dynamic>? ?? {},
      price: json['price'] as Map<String, dynamic>? ?? {},
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceSlug': serviceSlug,
      'serviceName': serviceName,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'input': input,
      'price': price,
      'notes': notes,
    };
  }

  CartItem copyWith({
    String? id,
    String? serviceSlug,
    String? serviceName,
    String? categoryId,
    String? subcategoryId,
    Map<String, dynamic>? input,
    Map<String, dynamic>? price,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      serviceSlug: serviceSlug ?? this.serviceSlug,
      serviceName: serviceName ?? this.serviceName,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      input: input ?? this.input,
      price: price ?? this.price,
      notes: notes ?? this.notes,
    );
  }
}
