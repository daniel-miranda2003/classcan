import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String username;
  final String password;
  final String role;

  const RegisterParams({
    required this.username,
    required this.password,
    this.role = 'teacher',
  });

  @override
  List<Object> get props => [username, password, role];
}

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  @override
  Future<UserEntity> call(RegisterParams params) async {
    final username = params.username.trim();

    if (username.isEmpty) {
      throw const AuthValidationException('El usuario es obligatorio');
    }
    if (params.password.length < 4) {
      throw const AuthValidationException(
        'La contraseña debe tener al menos 4 caracteres',
      );
    }

    return repository.register(
      UserEntity(
        username: username,
        password: params.password,
        role: params.role,
      ),
    );
  }
}
