import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // User Management
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    required String role,
    String? phone,
    String? address,
    String? shopName,
  }) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'address': address,
      'shopName': shopName,
      'createdAt': DateTime.now().toIso8601String(),
      'isActive': true,
    });
  }
  
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
  
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
    notifyListeners();
  }
  
  // Product Management
  Future<String> addProduct(ProductModel product) async {
    final docRef = await _db.collection('products').add(product.toMap());
    return docRef.id;
  }
  
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(productId).update(data);
    notifyListeners();
  }
  
  Future<void> deleteProduct(String productId) async {
    await _db.collection('products').doc(productId).update({'isActive': false});
    notifyListeners();
  }
  
  Stream<List<ProductModel>> getProducts({String? category, String? vendorId, bool activeOnly = true}) {
    Query query = _db.collection('products');
    
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (vendorId != null) {
      query = query.where('vendorId', isEqualTo: vendorId);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  Future<ProductModel?> getProductById(String productId) async {
    final doc = await _db.collection('products').doc(productId).get();
    if (doc.exists) {
      return ProductModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
  
  // Order Management
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _db.collection('orders').add(order.toMap());
    
    // Update stock
    for (var item in order.items) {
      final productDoc = await _db.collection('products').doc(item.productId).get();
      if (productDoc.exists) {
        final currentStock = productDoc.data()!['stock'] ?? 0;
        await _db.collection('products').doc(item.productId).update({
          'stock': currentStock - item.quantity,
        });
      }
    }
    
    notifyListeners();
    return docRef.id;
  }
  
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }
  
  Stream<List<OrderModel>> getOrders({String? customerId, String? vendorId, String? status}) {
    Query query = _db.collection('orders');
    
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (vendorId != null) {
      query = query.where('vendorId', isEqualTo: vendorId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.orderBy('orderDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _db.collection('orders').doc(orderId).get();
    if (doc.exists) {
      return OrderModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
  
  // Reviews Management
  Future<void> addReview({
    required String productId,
    required String userId,
    required String userName,
    required double rating,
    required String review,
  }) async {
    await _db.collection('products').doc(productId).collection('reviews').add({
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'review': review,
      'createdAt': DateTime.now().toIso8601String(),
    });
    
    // Update product rating
    final reviews = await _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .get();
    
    double totalRating = 0;
    for (var doc in reviews.docs) {
      totalRating += doc.data()['rating'];
    }
    
    final avgRating = totalRating / reviews.docs.length;
    
    await _db.collection('products').doc(productId).update({
      'rating': avgRating,
      'reviewCount': reviews.docs.length,
    });
    
    notifyListeners();
  }
  
  Stream<List<Map<String, dynamic>>> getReviews(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }
  
  // Analytics
  Future<Map<String, dynamic>> getVendorAnalytics(String vendorId) async {
    final orders = await _db
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .get();
    
    double totalRevenue = 0;
    int totalOrders = orders.docs.length;
    int completedOrders = 0;
    
    for (var doc in orders.docs) {
      final data = doc.data();
      if (data['status'] == 'delivered') {
        totalRevenue += data['totalAmount'];
        completedOrders++;
      }
    }
    
    final products = await _db
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .get();
    
    return {
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'totalProducts': products.docs.length,
    };
  }
  
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
  
  Future<List<Map<String, dynamic>>> getAllVendors() async {
    final snapshot = await _db.collection('users').where('role', isEqualTo: 'vendor').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
}