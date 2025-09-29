class ProductModel {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final int stock;
  final String unit; // kg, piece, dozen
  final bool isOrganic;
  final bool isSeasonal;
  final double rating;
  final int reviewCount;
  final DateTime createdAt;
  final bool isActive;
  final String? nutritionalInfo;
  
  ProductModel({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    required this.stock,
    this.unit = 'kg',
    this.isOrganic = false,
    this.isSeasonal = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    required this.createdAt,
    this.isActive = true,
    this.nutritionalInfo,
  });
  
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      stock: map['stock'] ?? 0,
      unit: map['unit'] ?? 'kg',
      isOrganic: map['isOrganic'] ?? false,
      isSeasonal: map['isSeasonal'] ?? false,
      rating: (map['rating'] ?? 0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
      nutritionalInfo: map['nutritionalInfo'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'stock': stock,
      'unit': unit,
      'isOrganic': isOrganic,
      'isSeasonal': isSeasonal,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'nutritionalInfo': nutritionalInfo,
    };
  }
}