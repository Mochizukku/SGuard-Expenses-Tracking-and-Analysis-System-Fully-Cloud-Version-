import 'package:fully_cloud_sguard/data/dataresources/firestore_datasource.dart';
import 'package:fully_cloud_sguard/data/models/expense_model.dart';
import 'package:fully_cloud_sguard/domain/entities/expense.dart';
import 'package:fully_cloud_sguard/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirestoreDatasource _datasource;

  ExpenseRepositoryImpl(this._datasource);

  @override
  Future<String> addExpense(Expense expense) async {
    final expenseModel = ExpenseModel(
      id: expense.id,
      userId: expense.userId,
      category: expense.category,
      amount: expense.amount,
      description: expense.description,
      date: expense.date,
      createdAt: expense.createdAt,
    );
    return _datasource.addExpense(expenseModel);
  }

  @override
  Future<void> updateExpense(
    String userId,
    String expenseId,
    Expense expense,
  ) async {
    final expenseModel = ExpenseModel(
      id: expense.id,
      userId: expense.userId,
      category: expense.category,
      amount: expense.amount,
      description: expense.description,
      date: expense.date,
      createdAt: expense.createdAt,
    );
    return _datasource.updateExpense(userId, expenseId, expenseModel);
  }

  @override
  Future<void> deleteExpense(String userId, String expenseId) {
    return _datasource.deleteExpense(userId, expenseId);
  }

  @override
  Future<List<Expense>> getUserExpenses(String userId) {
    return _datasource.getUserExpenses(userId);
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return _datasource.getExpensesByDateRange(userId, startDate, endDate);
  }

  @override
  Future<List<Expense>> getExpensesByCategory(String userId, String category) {
    return _datasource.getExpensesByCategory(userId, category);
  }

  @override
  Stream<List<Expense>> streamUserExpenses(String userId) {
    return _datasource.streamUserExpenses(userId);
  }
}
