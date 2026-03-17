import 'dart:convert';

import 'package:http/http.dart' as http;

/// FastAPI Gateway - All Firestore operations go through FastAPI backend
/// This prevents direct Firestore exposure and handles errors properly
class FastApiGateway {
  FastApiGateway({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Change this to your FastAPI server URL
  // Local: 'http://127.0.0.1:8000/api'
  // Production: 'https://your-fastapi-server.com/api'
  static const baseUrl = 'http://127.0.0.1:8000/api';

  // ============ USER OPERATIONS ============

  /// Save or update user account
  Future<void> saveUser({
    required String uid,
    required String email,
    required String name,
    required double balance,
  }) async {
    final uri = Uri.parse('$baseUrl/users');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': uid,
        'email': email,
        'name': name,
        'balance': balance,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save user: ${response.body}');
    }
  }

  /// Get user account
  Future<Map<String, dynamic>> getUser(String userId) async {
    final uri = Uri.parse('$baseUrl/users/$userId');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get user: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw Exception('User not found');
    }

    return json['data'] as Map<String, dynamic>;
  }

  /// Update user balance
  Future<void> updateUserBalance(String userId, double newBalance) async {
    final uri = Uri.parse('$baseUrl/users/$userId/balance');
    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'balance': newBalance}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update balance: ${response.body}');
    }
  }

  // ============ EXPENSE OPERATIONS ============

  /// Add new expense
  Future<String> addExpense({
    required String userId,
    required String category,
    required double amount,
    required String description,
    required String date,
  }) async {
    final uri = Uri.parse('$baseUrl/users/$userId/expenses');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'category': category,
        'amount': amount,
        'description': description,
        'date': date,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add expense: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['expenseId'] as String;
  }

  /// Get all expenses for user
  Future<List<Map<String, dynamic>>> getExpenses(String userId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/expenses');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get expenses: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final expenses = json['data'] as List<dynamic>;
    return expenses.cast<Map<String, dynamic>>();
  }

  /// Get single expense
  Future<Map<String, dynamic>> getExpense(String userId, String expenseId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/expenses/$expenseId');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get expense: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['success'] != true) {
      throw Exception('Expense not found');
    }

    return json['data'] as Map<String, dynamic>;
  }

  /// Update expense
  Future<void> updateExpense({
    required String userId,
    required String expenseId,
    String? category,
    double? amount,
    String? description,
    String? date,
  }) async {
    final uri = Uri.parse('$baseUrl/users/$userId/expenses/$expenseId');
    final body = <String, dynamic>{};

    if (category != null) body['category'] = category;
    if (amount != null) body['amount'] = amount;
    if (description != null) body['description'] = description;
    if (date != null) body['date'] = date;

    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update expense: ${response.body}');
    }
  }

  /// Delete expense
  Future<void> deleteExpense(String userId, String expenseId) async {
    final uri = Uri.parse('$baseUrl/users/$userId/expenses/$expenseId');
    final response = await _client.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete expense: ${response.body}');
    }
  }

  /// Get expenses by category
  Future<List<Map<String, dynamic>>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    final uri = Uri.parse('$baseUrl/users/$userId/expenses/by-category/$category');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get expenses by category: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final expenses = json['data'] as List<dynamic>;
    return expenses.cast<Map<String, dynamic>>();
  }

  /// Get expenses by date range
  Future<List<Map<String, dynamic>>> getExpensesByDateRange(
    String userId,
    String startDate,
    String endDate,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/users/$userId/expenses/by-date-range?start_date=$startDate&end_date=$endDate',
    );
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get expenses by date range: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final expenses = json['data'] as List<dynamic>;
    return expenses.cast<Map<String, dynamic>>();
  }

  /// Get profile summary with statistics
  Future<Map<String, dynamic>> fetchProfileSummary(String userId) async {
    final uri = Uri.parse('$baseUrl/profile-summary/$userId');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile summary: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['data'] as Map<String, dynamic>;
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await _client.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
