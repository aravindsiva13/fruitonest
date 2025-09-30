class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String role; // customer, vendor, admin
  final String? address;
  final String? profileImage;
  final DateTime createdAt;
  final bool isActive;
  
  // Vendor specific
  final String? shopName;
  final String? shopLogo;
  final List<String>? deliveryAreas;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.role,
    this.address,
    this.profileImage,
    required this.createdAt,
    this.isActive = true,
    this.shopName,
    this.shopLogo,
    this.deliveryAreas,
  });
  
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? 'customer',
      address: map['address'],
      profileImage: map['profileImage'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isActive: map['isActive'] ?? true,
      shopName: map['shopName'],
      shopLogo: map['shopLogo'],
      deliveryAreas: map['deliveryAreas'] != null ? List<String>.from(map['deliveryAreas']) : null,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'address': address,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'shopName': shopName,
      'shopLogo': shopLogo,
      'deliveryAreas': deliveryAreas,
    };
  }
}