import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/attendance_record_model.dart';

abstract class AttendanceLocalDataSource {
  Future<List<AttendanceRecordModel>> getAttendanceByCourseAndDate(
    int courseId,
    String date,
  );

  Future<void> saveAttendanceBatch(List<AttendanceRecordModel> records);
}

class AttendanceLocalDataSourceImpl implements AttendanceLocalDataSource {
  final DatabaseHelper dbHelper;

  const AttendanceLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<AttendanceRecordModel>> getAttendanceByCourseAndDate(
    int courseId,
    String date,
  ) async {
    try {
      final db = await dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableAttendanceRecord,
        where: 'courseId = ? AND date = ?',
        whereArgs: [courseId, date],
        orderBy: 'studentId ASC',
      );
      return rows.map(AttendanceRecordModel.fromMap).toList();
    } catch (e) {
      throw LocalDatabaseException('Error al cargar la asistencia: $e');
    }
  }

  @override
  Future<void> saveAttendanceBatch(List<AttendanceRecordModel> records) async {
    if (records.isEmpty) return;

    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        for (final record in records) {
          final map = record.toMap()..remove('id');
          final updated = await txn.update(
            DatabaseHelper.tableAttendanceRecord,
            {'status': record.status},
            where: 'studentId = ? AND courseId = ? AND date = ?',
            whereArgs: [record.studentId, record.courseId, record.date],
          );
          if (updated == 0) {
            await txn.insert(DatabaseHelper.tableAttendanceRecord, map);
          }
        }

        final studentIds = records.map((r) => r.studentId).toSet();
        for (final studentId in studentIds) {
          final count =
              Sqflite.firstIntValue(
                await txn.rawQuery(
                  'SELECT COUNT(*) FROM ${DatabaseHelper.tableAttendanceRecord} '
                  'WHERE studentId = ? AND status = ?',
                  [studentId, 'ABSENT'],
                ),
              ) ??
              0;
          await txn.update(
            DatabaseHelper.tableStudent,
            {'absences': count},
            where: 'id = ?',
            whereArgs: [studentId],
          );
        }
      });
    } on AttendanceValidationException {
      rethrow;
    } catch (e) {
      throw LocalDatabaseException('Error al guardar la asistencia: $e');
    }
  }
}
