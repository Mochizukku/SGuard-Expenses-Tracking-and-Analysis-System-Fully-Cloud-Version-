import 'package:fully_cloud_sguard/data/dataresources/http_datasource.dart';
import 'package:fully_cloud_sguard/data/repositories/expense_http_repository_impl.dart';
import 'package:fully_cloud_sguard/data/repositories/user_http_repository_impl.dart';
import 'package:fully_cloud_sguard/data/services/fastapi_gateway.dart';
import 'package:fully_cloud_sguard/presentation/pages/analysis/domain/repositories/expense_repository.dart';
import 'package:fully_cloud_sguard/presentation/pages/analysis/domain/repositories/user_repository.dart';

/// Repository provider with support for both Firestore (direct) and HTTP (FastAPI gateway)
class RepositoryProvider {
  static final _instance = RepositoryProvider._();

  late final ExpenseRepository _expenseRepository;
  late final UserRepository _userRepository;

  RepositoryProvider._() {
    /// Using FastAPI gateway for all repository implementations
    /// This approach is safer with errors handled on backend
    /// To use direct Firestore, uncomment the code below and set USE_HTTP_GATEWAY = false
    
    // Use FastAPI gateway (recommended)
    final httpDatasource = HttpDatasource(gateway: FastApiGateway());
    _expenseRepository = ExpenseHttpRepositoryImpl(httpDatasource);
    _userRepository = UserHttpRepositoryImpl(httpDatasource);
    
    // Alternative: Use direct Firestore (uncomment to switch)
    // final firestoreDatasource = FirestoreDatasource();
    // _expenseRepository = ExpenseRepositoryImpl(firestoreDatasource);
    // _userRepository = UserRepositoryImpl(firestoreDatasource);
  }

  factory RepositoryProvider() {
    return _instance;
  }

  ExpenseRepository get expenseRepository => _expenseRepository;
  UserRepository get userRepository => _userRepository;
}
