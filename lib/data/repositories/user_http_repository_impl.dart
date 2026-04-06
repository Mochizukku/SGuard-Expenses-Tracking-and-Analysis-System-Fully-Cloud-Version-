import 'package:fully_cloud_sguard/data/dataresources/http_datasource.dart';
import 'package:fully_cloud_sguard/data/models/user_account_model.dart';
import 'package:fully_cloud_sguard/presentation/pages/analysis/domain/entities/user_account.dart';
import 'package:fully_cloud_sguard/presentation/pages/analysis/domain/repositories/user_repository.dart';

class UserHttpRepositoryImpl implements UserRepository {
  final HttpDatasource _datasource;

  UserHttpRepositoryImpl(this._datasource);

  @override
  Future<void> saveUserAccount(UserAccount user) async {
    final userModel = UserAccountModel(
      uid: user.uid,
      email: user.email,
      name: user.name,
      balance: user.balance,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
    return _datasource.saveUserAccount(userModel);
  }

  @override
  Future<UserAccount?> getUserAccount(String uid) {
    return _datasource.getUserAccount(uid);
  }

  @override
  Future<void> updateUserBalance(String uid, double newBalance) {
    return _datasource.updateUserBalance(uid, newBalance);
  }
}
