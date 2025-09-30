class OrderModel {
  final String id;
  final String customerId;
  final String vendorId;
  final List<OrderItem> items;
  final double totalAmount;
  final String deliveryAddress;
  final String? deliveryInstructions;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String status; // pending, confirmed, processing, dispatched, delivered, cancelled
  final String paymentMethod;
  final String paymentStatus; // pending, paid, failed, refunded
  final String? trackingInfo;
  final String? cancellationReason;
  
  OrderModel({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    this.deliveryInstructions,
    required this.orderDate,
    this.deliveryDate,
    this.status = 'pending',
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.trackingInfo,
    this.cancellationReason,
  });
  
  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      customerId: map['customerId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      items: (map['items'] as List).map((item) => OrderItem.fromMap(item)).toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      deliveryAddress: map['deliveryAddress'] ?? '',
      deliveryInstructions: map['deliveryInstructions'],
      orderDate: DateTime.parse(map['orderDate'] ?? DateTime.now().toIso8601String()),
      deliveryDate: map['deliveryDate'] != null ? DateTime.parse(map['deliveryDate']) : null,
      status: map['status'] ?? 'pending',
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      trackingInfo: map['trackingInfo'],
      cancellationReason: map['cancellationReason'],
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'vendorId': vendorId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'deliveryInstructions': deliveryInstructions,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'trackingInfo': trackingInfo,
      'cancellationReason': cancellationReason,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String unit;
  
  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.unit,
  });
  
  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? 'kg',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }
}