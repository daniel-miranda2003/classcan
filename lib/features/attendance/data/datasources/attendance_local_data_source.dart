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
        final batch = txn.batch();
        for (final record in records) {
          final map = record.toMap()..remove('id');
          batch.insert(
            DatabaseHelper.tableAttendanceRecord,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);

        final studentIds = records.map((r) => r.studentId).toSet();
        if (studentIds.isNotEmpty) {
          final studentIdsList = studentIds.join(',');
          await txn.execute('''
            UPDATE ${DatabaseHelper.tableStudent}
            SET absences = (
              SELECT COUNT(*)
              FROM ${DatabaseHelper.tableAttendanceRecord}
              WHERE ${DatabaseHelper.tableAttendanceRecord}.studentId = ${DatabaseHelper.tableStudent}.id
                AND status = 'ABSENT'
            )
            WHERE id IN ($studentIdsList)
          ''');
        }
      });
    } on AttendanceValidationException {
      rethrow;
    } catch (e) {
      throw LocalDatabaseException('Error al guardar la asistencia: $e');
    }
  }
}
