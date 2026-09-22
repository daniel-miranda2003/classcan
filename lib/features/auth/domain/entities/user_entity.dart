import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int? id;
  final String username;
  final String password;
  final String role;

  const UserEntity({
    this.id,
    required this.username,
    required this.password,
    required this.role,
  });

  @override
  List<Object?> get props => [id, username, password, role];
}
