import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Wrappers around Firebase auth and Firestore operations.
class FirebaseService {
  FirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  Future<QuerySnapshot> fetchRecentRecords() {
    return _firestore
        .collection('records')
        .orderBy('date', descending: true)
        .limit(10)
        .get();
  }
}
