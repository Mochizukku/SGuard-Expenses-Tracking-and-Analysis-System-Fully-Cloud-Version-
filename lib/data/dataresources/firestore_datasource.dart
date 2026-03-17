import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fully_cloud_sguard/data/models/expense_model.dart';
import 'package:fully_cloud_sguard/data/models/user_account_model.dart';

class FirestoreDatasource {
  final FirebaseFirestore _firestore;

  FirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ============ USER OPERATIONS ============

  /// Create or update user account in Firestore
  Future<void> saveUserAccount(UserAccountModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(
            user.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to save user account: $e');
    }
  }

  /// Get user account by UID
  Future<UserAccountModel?> getUserAccount(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserAccountModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user account: $e');
    }
  }

  /// Update user balance
  Future<void> updateUserBalance(String uid, double newBalance) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'balance': newBalance,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update user balance: $e');
    }
  }

  // ============ EXPENSE OPERATIONS ============

  /// Add a new expense
  Future<String> addExpense(ExpenseModel expense) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(expense.userId)
          .collection('expenses')
          .add(expense.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Update an existing expense
  Future<void> updateExpense(String userId, String expenseId, ExpenseModel expense) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expenseId)
          .update(expense.toMap());
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Get all expenses for a user
  Future<List<ExpenseModel>> getUserExpenses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user expenses: $e');
    }
  }

  /// Get expenses for a specific date range
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses by date range: $e');
    }
  }

  /// Get expenses by category
  Future<List<ExpenseModel>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .where('category', isEqualTo: category)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses by category: $e');
    }
  }

  /// Stream all expenses for real-time updates
  Stream<List<ExpenseModel>> streamUserExpenses(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
