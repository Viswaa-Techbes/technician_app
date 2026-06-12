class CctvCameraType {
  final String id;
  final String name;
  final String slug;
  final String description;
  final double installationPrice;

  const CctvCameraType({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.installationPrice,
  });

  factory CctvCameraType.fromJson(Map<String, dynamic> json) {
    return CctvCameraType(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      installationPrice: (json['installationPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CctvAddon {
  final String id;
  final String name;
  final String slug;
  final double price;
  final String? unit;
  final String? description;

  const CctvAddon({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.unit,
    this.description,
  });

  factory CctvAddon.fromJson(Map<String, dynamic> json) {
    return CctvAddon(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
    );
  }
}

class CctvPriceResult {
  final double grandTotal;
  final double taxTotal;
  final double taxableAmount;
  final Map<String, double> breakdown;

  const CctvPriceResult({
    required this.grandTotal,
    required this.taxTotal,
    required this.taxableAmount,
    required this.breakdown,
  });

  factory CctvPriceResult.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as Map<String, dynamic>? ?? json;
    final breakdownMap = rawData['priceBreakdown'] as Map<String, dynamic>? ?? {};
    
    final breakdown = breakdownMap.map((key, value) => MapEntry(key, (value as num).toDouble()));

    return CctvPriceResult(
      grandTotal: (breakdown['grandTotal'] ?? (rawData['grandTotal'] as num?)?.toDouble() ?? 0.0),
      taxTotal: (breakdown['taxTotal'] ?? (rawData['taxTotal'] as num?)?.toDouble() ?? 0.0),
      taxableAmount: (breakdown['taxableAmount'] ?? (rawData['taxableAmount'] as num?)?.toDouble() ?? 0.0),
      breakdown: breakdown,
    );
  }
}
