import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
    required String username,
    required String password,
  });

  Future<UserEntity> register(UserEntity user);
}
