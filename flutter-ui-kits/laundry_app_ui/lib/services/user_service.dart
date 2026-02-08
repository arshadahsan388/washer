import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String phone,
    String? address,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'phone': phone,
        'address': address ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Add delivery address
  Future<bool> addDeliveryAddress({
    required String label,
    required String address,
    required String city,
    required String zipCode,
    bool isDefault = false,
  }) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // If this is set as default, unset all other defaults
      if (isDefault) {
        final addresses = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .get();

        for (var doc in addresses.docs) {
          await doc.reference.update({'isDefault': false});
        }
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .add({
        'label': label,
        'address': address,
        'city': city,
        'zipCode': zipCode,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error adding delivery address: $e');
      return false;
    }
  }

  // Get all delivery addresses
  Stream<QuerySnapshot> getDeliveryAddresses() {
    final user = currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .snapshots();
  }

  // Delete delivery address
  Future<bool> deleteDeliveryAddress(String addressId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting address: $e');
      return false;
    }
  }

  // Set default address
  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Unset all defaults
      final addresses = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .get();

      for (var doc in addresses.docs) {
        await doc.reference.update({'isDefault': false});
      }

      // Set new default
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(addressId)
          .update({'isDefault': true});

      return true;
    } catch (e) {
      print('Error setting default address: $e');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) return false;

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final user = currentUser;
      if (user == null) {
        return {
          'totalOrders': 0,
          'totalSpent': 0.0,
          'pendingOrders': 0,
          'completedOrders': 0,
        };
      }

      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      int totalOrders = ordersSnapshot.docs.length;
      double totalSpent = 0.0;
      int pendingOrders = 0;
      int completedOrders = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final price = (data['totalPrice'] ?? 0).toDouble();
        totalSpent += price;

        final status = data['status'] ?? '';
        if (status == 'Pending' || status == 'Processing' || status == 'Washing') {
          pendingOrders++;
        } else if (status == 'Completed') {
          completedOrders++;
        }
      }

      return {
        'totalOrders': totalOrders,
        'totalSpent': totalSpent,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'totalOrders': 0,
        'totalSpent': 0.0,
        'pendingOrders': 0,
        'completedOrders': 0,
      };
    }
  }
}
