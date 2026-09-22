import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/security/password_hasher.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> login(String username, String password);
  Future<UserModel> register(UserModel user);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final DatabaseHelper dbHelper;

  const AuthLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<UserModel?> login(String username, String password) async {
    try {
      final db = await dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableUser,
        where: 'username = ? AND password = ?',
        whereArgs: [username, hashPassword(username, password)],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return UserModel.fromMap(rows.first);
    } on DatabaseException {
      rethrow;
    } catch (e) {
      throw LocalDatabaseException('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<UserModel> register(UserModel user) async {
    try {
      final db = await dbHelper.database;
      final hashed = user.copyWith(
        password: hashPassword(user.username, user.password),
      );
      final id = await db.insert(
        DatabaseHelper.tableUser,
        hashed.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return hashed.copyWith(id: id);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DuplicateUserException('El usuario "${user.username}" ya existe');
      }
      rethrow;
    } catch (e) {
      throw LocalDatabaseException('Error al registrar usuario: $e');
    }
  }
}
