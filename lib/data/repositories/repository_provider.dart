import 'package:fully_cloud_sguard/data/dataresources/firestore_datasource.dart';
import 'package:fully_cloud_sguard/data/dataresources/http_datasource.dart';
import 'package:fully_cloud_sguard/data/repositories/expense_http_repository_impl.dart';
import 'package:fully_cloud_sguard/data/repositories/expense_repository_impl.dart';
import 'package:fully_cloud_sguard/data/repositories/user_http_repository_impl.dart';
import 'package:fully_cloud_sguard/data/repositories/user_repository_impl.dart';
import 'package:fully_cloud_sguard/data/services/fastapi_gateway.dart';
import 'package:fully_cloud_sguard/domain/repositories/expense_repository.dart';
import 'package:fully_cloud_sguard/domain/repositories/user_repository.dart';

/// Repository provider with support for both Firestore (direct) and HTTP (FastAPI gateway)
class RepositoryProvider {
  static final _instance = RepositoryProvider._();

  late final ExpenseRepository _expenseRepository;
  late final UserRepository _userRepository;

  RepositoryProvider._() {
    /// Change USE_HTTP_GATEWAY to false if you want to use direct Firestore
    /// true = Use FastAPI gateway (recommended, no ClientException errors)
    /// false = Use direct Firestore (requires Firestore SDK on device)
    const bool USE_HTTP_GATEWAY = true;

    if (USE_HTTP_GATEWAY) {
      // Use FastAPI gateway (safer, errors handled on backend)
      final httpDatasource = HttpDatasource(gateway: FastApiGateway());
      _expenseRepository = ExpenseHttpRepositoryImpl(httpDatasource);
      _userRepository = UserHttpRepositoryImpl(httpDatasource);
    } else {
      // Use direct Firestore (requires Firestore SDK)
      final firestoreDatasource = FirestoreDatasource();
      _expenseRepository = ExpenseRepositoryImpl(firestoreDatasource);
      _userRepository = UserRepositoryImpl(firestoreDatasource);
    }
  }

  factory RepositoryProvider() {
    return _instance;
  }

  ExpenseRepository get expenseRepository => _expenseRepository;
  UserRepository get userRepository => _userRepository;
}
