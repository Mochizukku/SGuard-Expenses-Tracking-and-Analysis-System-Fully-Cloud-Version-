import 'package:fully_cloud_sguard/data/models/expense_model.dart';
import 'package:fully_cloud_sguard/data/models/user_account_model.dart';
import 'package:fully_cloud_sguard/data/services/fastapi_gateway.dart';

/// HTTP datasource that connects to FastAPI backend
/// This is an alternative to direct Firestore access
/// FastAPI gateway handles Firestore operations on the backend
class HttpDatasource {
  final FastApiGateway _gateway;

  HttpDatasource({FastApiGateway? gateway})
      : _gateway = gateway ?? FastApiGateway();

  // ============ USER OPERATIONS ============

  /// Save or update user account via FastAPI
  Future<void> saveUserAccount(UserAccountModel user) async {
    try {
      await _gateway.saveUser(
        uid: user.uid,
        email: user.email,
        name: user.name,
        balance: user.balance,
      );
    } catch (e) {
      throw Exception('Failed to save user account: $e');
    }
  }

  /// Get user account via FastAPI
  Future<UserAccountModel?> getUserAccount(String uid) async {
    try {
      final data = await _gateway.getUser(uid);
      return UserAccountModel.fromMap(data, uid);
    } catch (e) {
      throw Exception('Failed to get user account: $e');
    }
  }

  /// Update user balance via FastAPI
  Future<void> updateUserBalance(String uid, double newBalance) async {
    try {
      await _gateway.updateUserBalance(uid, newBalance);
    } catch (e) {
      throw Exception('Failed to update user balance: $e');
    }
  }

  // ============ EXPENSE OPERATIONS ============

  /// Add a new expense via FastAPI
  Future<String> addExpense(ExpenseModel expense) async {
    try {
      return await _gateway.addExpense(
        userId: expense.userId,
        category: expense.category,
        amount: expense.amount,
        description: expense.description,
        date: expense.date.toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Update an existing expense via FastAPI
  Future<void> updateExpense(
    String userId,
    String expenseId,
    ExpenseModel expense,
  ) async {
    try {
      await _gateway.updateExpense(
        userId: userId,
        expenseId: expenseId,
        category: expense.category,
        amount: expense.amount,
        description: expense.description,
        date: expense.date.toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  /// Delete an expense via FastAPI
  Future<void> deleteExpense(String userId, String expenseId) async {
    try {
      await _gateway.deleteExpense(userId, expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  /// Get all expenses for a user via FastAPI
  Future<List<ExpenseModel>> getUserExpenses(String userId) async {
    try {
      final data = await _gateway.getExpenses(userId);
      return data
          .map((expense) => ExpenseModel.fromMap(expense, expense['id']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user expenses: $e');
    }
  }

  /// Get expenses for a specific date range via FastAPI
  Future<List<ExpenseModel>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final data = await _gateway.getExpensesByDateRange(
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      );
      return data
          .map((expense) => ExpenseModel.fromMap(expense, expense['id']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses by date range: $e');
    }
  }

  /// Get expenses by category via FastAPI
  Future<List<ExpenseModel>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    try {
      final data = await _gateway.getExpensesByCategory(userId, category);
      return data
          .map((expense) => ExpenseModel.fromMap(expense, expense['id']))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses by category: $e');
    }
  }

  /// Note: Streaming is not supported via HTTP
  /// Use regular polling with Future instead
  Future<List<ExpenseModel>> pollUserExpenses(String userId) async {
    return getUserExpenses(userId);
  }
}
