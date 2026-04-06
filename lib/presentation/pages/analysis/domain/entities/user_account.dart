class UserAccount {
  final String uid;
  final String email;
  final String name;
  final double balance;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAccount({
    required this.uid,
    required this.email,
    required this.name,
    required this.balance,
    required this.createdAt,
    required this.updatedAt,
  });

  UserAccount copyWith({
    String? uid,
    String? email,
    String? name,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
