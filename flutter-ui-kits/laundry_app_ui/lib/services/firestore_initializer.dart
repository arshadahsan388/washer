import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreInitializer {
  static Future<void> initializeCollections() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      
      // Check if user is authenticated
      User? user = auth.currentUser;
      
      print('Initializing Firestore collections...');
      print('Current user: ${user?.email ?? "Not logged in"}');
      
      // Create users collection if doesn't exist
      try {
        final usersRef = firestore.collection('users');
        final usersSnapshot = await usersRef.limit(1).get();
        
        if (usersSnapshot.docs.isEmpty) {
          print('Creating users collection...');
          await usersRef.doc('_init').set({
            'initialized': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Users collection created');
        }
      } catch (e) {
        print('Error creating users collection: $e');
      }
      
      // Create orders collection if doesn't exist
      try {
        final ordersRef = firestore.collection('orders');
        final ordersSnapshot = await ordersRef.limit(1).get();
        
        if (ordersSnapshot.docs.isEmpty) {
          print('Creating orders collection...');
          await ordersRef.doc('_init').set({
            'initialized': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Orders collection created');
        }
      } catch (e) {
        print('Error creating orders collection: $e');
      }
      
      print('Firestore initialization complete');
    } catch (e) {
      print('Error initializing Firestore: $e');
    }
  }
  
  // Test Firestore connection
  static Future<bool> testFirestoreConnection() async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      await firestore.collection('_test').doc('test').set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await firestore.collection('_test').doc('test').delete();
      print('Firestore connection test: SUCCESS');
      return true;
    } catch (e) {
      print('Firestore connection test: FAILED - $e');
      return false;
    }
  }
}
