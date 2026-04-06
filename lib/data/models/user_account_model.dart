import 'package:fully_cloud_sguard/presentation/pages/analysis/domain/entities/user_account.dart';

class UserAccountModel extends UserAccount {
  UserAccountModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.balance,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserAccountModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserAccountModel(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
