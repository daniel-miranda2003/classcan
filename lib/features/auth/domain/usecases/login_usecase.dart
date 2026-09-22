import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  final String username;
  final String password;

  const LoginParams({required this.username, required this.password});

  @override
  List<Object> get props => [username, password];
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<UserEntity> call(LoginParams params) async {
    final username = params.username.trim();
    final password = params.password;

    if (username.isEmpty || password.isEmpty) {
      throw const AuthValidationException(
        'Usuario y contraseña son obligatorios',
      );
    }

    return repository.login(username: username, password: password);
  }
}
