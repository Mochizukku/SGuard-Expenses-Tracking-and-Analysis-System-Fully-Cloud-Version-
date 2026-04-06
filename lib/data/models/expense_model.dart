import 'package:fully_cloud_sguard/presentation/pages/analysis/domain/entities/expense.dart';

class ExpenseModel extends Expense {
  ExpenseModel({
    required super.id,
    required super.userId,
    required super.category,
    required super.amount,
    required super.description,
    required super.date,
    required super.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
