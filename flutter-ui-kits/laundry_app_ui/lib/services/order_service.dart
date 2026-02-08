import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new order
  Future<String> createOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required String pickupAddress,
    required DateTime pickupDate,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
  }) async {
    try {
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'pickupAddress': pickupAddress,
        'pickupDate': Timestamp.fromDate(pickupDate),
        'items': items,
        'totalPrice': totalPrice,
        'status': 'pending', // pending, processing, completed, cancelled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return orderRef.id;
    } catch (e) {
      print('Create order error: $e');
      throw e;
    }
  }

  // Get user orders
  Stream<QuerySnapshot> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  // Get single order
  Future<DocumentSnapshot> getOrder(String orderId) async {
    try {
      return await _firestore.collection('orders').doc(orderId).get();
    } catch (e) {
      print('Get order error: $e');
      throw e;
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Update order status error: $e');
      throw e;
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Cancel order error: $e');
      throw e;
    }
  }

  // Get all orders (for admin)
  Stream<QuerySnapshot> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get orders by status
  Stream<QuerySnapshot> getOrdersByStatus(String status) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Add rating and review to order
  Future<void> addReview({
    required String orderId,
    required double rating,
    required String review,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'rating': rating,
        'review': review,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Add review error: $e');
      throw e;
    }
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStats(String userId) async {
    try {
      QuerySnapshot orders = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      int totalOrders = orders.docs.length;
      int completedOrders = orders.docs
          .where((doc) => (doc.data() as Map)['status'] == 'completed')
          .length;
      int pendingOrders = orders.docs
          .where((doc) => (doc.data() as Map)['status'] == 'pending')
          .length;

      double totalSpent = 0;
      for (var doc in orders.docs) {
        totalSpent += ((doc.data() as Map)['totalPrice'] ?? 0).toDouble();
      }

      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'pendingOrders': pendingOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      print('Get stats error: $e');
      return {
        'totalOrders': 0,
        'completedOrders': 0,
        'pendingOrders': 0,
        'totalSpent': 0.0,
      };
    }
  }
}
