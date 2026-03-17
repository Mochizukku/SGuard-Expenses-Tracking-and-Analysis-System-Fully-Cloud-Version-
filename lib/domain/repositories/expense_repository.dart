import 'package:fully_cloud_sguard/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<String> addExpense(Expense expense);
  Future<void> updateExpense(String userId, String expenseId, Expense expense);
  Future<void> deleteExpense(String userId, String expenseId);
  Future<List<Expense>> getUserExpenses(String userId);
  Future<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<List<Expense>> getExpensesByCategory(String userId, String category);
  Stream<List<Expense>> streamUserExpenses(String userId);
}
