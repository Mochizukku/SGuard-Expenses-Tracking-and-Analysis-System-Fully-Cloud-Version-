import 'package:fully_cloud_sguard/presentation/pages/analysis/domain/entities/user_account.dart';

abstract class UserRepository {
  Future<void> saveUserAccount(UserAccount user);
  Future<UserAccount?> getUserAccount(String uid);
  Future<void> updateUserBalance(String uid, double newBalance);
}
