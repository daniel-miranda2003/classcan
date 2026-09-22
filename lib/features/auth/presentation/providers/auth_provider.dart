import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

enum AuthStatus { initial, loading, authenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState._({required this.status, this.user, this.errorMessage});

  const AuthState.initial() : this._(status: AuthStatus.initial);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState._(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage];
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.initial();

  Future<void> login({
    required String username,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await sl<LoginUseCase>()(
        LoginParams(username: username, password: password),
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanize(e),
      );
    }
  }

  Future<void> register({
    required String username,
    required String password,
    String role = 'teacher',
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await sl<RegisterUseCase>()(
        RegisterParams(username: username, password: password, role: role),
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _humanize(e),
      );
    }
  }

  void logout() => state = const AuthState.initial();

  void clearError() {
    if (state.hasError) {
      state = state.copyWith(status: AuthStatus.initial, errorMessage: null);
    }
  }

  String _humanize(Object e) {
    final raw = e.toString();
    const prefixes = [
      'InvalidCredentialsException: ',
      'DuplicateUserException: ',
      'AuthValidationException: ',
      'LocalDatabaseException: ',
      'NotFoundException: ',
      'Exception: ',
    ];
    for (final p in prefixes) {
      if (raw.startsWith(p)) return raw.substring(p.length);
    }
    return raw;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
