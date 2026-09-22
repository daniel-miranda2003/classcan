import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;

  const AuthRepositoryImpl({required this.localDataSource});

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
  }) async {
    final user = await localDataSource.login(username, password);
    if (user == null) {
      throw const InvalidCredentialsException();
    }
    return user;
  }

  @override
  Future<UserEntity> register(UserEntity user) async {
    final model = UserModel(
      id: user.id,
      username: user.username,
      password: user.password,
      role: user.role,
    );
    try {
      return await localDataSource.register(model);
    } on DuplicateUserException {
      rethrow;
    } on LocalDatabaseException {
      rethrow;
    }
  }
}
