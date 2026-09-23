import 'package:flutter/foundation.dart';
import '../security/password_hasher.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static const _dbName = 'classcan.db';
  static const _dbVersion = 5;

  static const tableUser = 'User';
  static const tableCourse = 'Course';
  static const tableStudent = 'Student';
  static const tableAttendanceRecord = 'AttendanceRecord';
  static const tableAssessment = 'Assessment';
  static const tableGrade = 'Grade';
  static const tableEnrollment = 'Enrollment';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      Future<Database> openWeb() => openDatabase(
            _dbName,
            version: _dbVersion,
            onConfigure: _onConfigure,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
          );
      try {
        databaseFactory = databaseFactoryFfiWeb;
        return await openWeb();
      } catch (_) {
        databaseFactory = databaseFactoryFfiWebNoWebWorker;
        return await openWeb();
      }
    }
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, _dbName);
    return await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUser (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCourse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        grade TEXT NOT NULL,
        color TEXT NOT NULL,
        userId INTEGER NOT NULL,
        FOREIGN KEY (userId) REFERENCES $tableUser (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableStudent (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        attendanceStatus TEXT NOT NULL DEFAULT 'PRESENT',
        absences INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAttendanceRecord (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        courseId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL CHECK (status IN ('PRESENT','ABSENT','LATE')),
        FOREIGN KEY (studentId) REFERENCES $tableStudent (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        FOREIGN KEY (courseId) REFERENCES $tableCourse (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        UNIQUE(studentId, courseId, date)
      )
    ''');

    await db.execute('CREATE INDEX idx_course_userId ON $tableCourse(userId)');
    await db.execute(
      'CREATE INDEX idx_attendance_student ON $tableAttendanceRecord(studentId)',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_course_date ON $tableAttendanceRecord(courseId, date)',
    );

    await _createV2Tables(db);
    await _createV3Tables(db);
    await _migrateStudentV4(db);
    await _seedDefaultUser(db);
  }

  Future<void> _seedDefaultUser(Database db) async {
    await db.insert(
      tableUser,
      {
        'username': 'classcan',
        'password': hashPassword('classcan', 'classcan'),
        'role': 'Profesor',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createV2Tables(db);
    }
    if (oldVersion < 3) {
      await _createV3Tables(db);
      await db.execute(
        'INSERT OR IGNORE INTO $tableEnrollment (studentId, courseId) '
        'SELECT $tableStudent.id, $tableCourse.id '
        'FROM $tableStudent, $tableCourse',
      );
    }
    if (oldVersion < 4) {
      await _migrateStudentV4(db);
    }
    if (oldVersion < 5) {
      await _seedDefaultUser(db);
    }
  }

  Future<void> _migrateStudentV4(Database db) async {
    Future<Set<String>> columnNames() async {
      final cols = await db.rawQuery('PRAGMA table_info($tableStudent)');
      return cols.map((c) => c['name'] as String).toSet();
    }

    Future<void> addColumn(String name) async {
      if ((await columnNames()).contains(name)) return;
      await db.execute(
        'ALTER TABLE $tableStudent ADD COLUMN $name TEXT NOT NULL DEFAULT \'\'',
      );
    }

    Future<void> dropColumn(String name) async {
      if (!(await columnNames()).contains(name)) return;
      try {
        await db.execute('ALTER TABLE $tableStudent DROP COLUMN $name');
      } catch (_) {
        await db.execute(
          'UPDATE $tableStudent SET $name = \'\' WHERE $name IS NULL',
        );
      }
    }

    await addColumn('firstName');
    await addColumn('middleName');
    await addColumn('paternalLastName');
    await addColumn('maternalLastName');

    if ((await columnNames()).contains('fullName')) {
      await db.execute(
        'UPDATE $tableStudent SET firstName = fullName WHERE firstName = \'\'',
      );
      await dropColumn('fullName');
    }
    if ((await columnNames()).contains('lastName')) {
      await db.execute(
        'UPDATE $tableStudent SET paternalLastName = lastName WHERE paternalLastName = \'\'',
      );
      await dropColumn('lastName');
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableAssessment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseId INTEGER NOT NULL,
        title TEXT NOT NULL,
        type TEXT NOT NULL CHECK (type IN ('TASK','EXAM')),
        maxScore REAL NOT NULL DEFAULT 10,
        date TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES $tableCourse (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableGrade (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assessmentId INTEGER NOT NULL,
        studentId INTEGER NOT NULL,
        score REAL NOT NULL,
        FOREIGN KEY (assessmentId) REFERENCES $tableAssessment (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        FOREIGN KEY (studentId) REFERENCES $tableStudent (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        UNIQUE(assessmentId, studentId)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_assessment_course_type ON $tableAssessment(courseId, type)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_grade_assessment ON $tableGrade(assessmentId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_grade_student ON $tableGrade(studentId)',
    );
  }

  Future<void> _createV3Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableEnrollment (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        studentId INTEGER NOT NULL,
        courseId INTEGER NOT NULL,
        FOREIGN KEY (studentId) REFERENCES $tableStudent (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        FOREIGN KEY (courseId) REFERENCES $tableCourse (id)
          ON DELETE CASCADE
          ON UPDATE CASCADE,
        UNIQUE(studentId, courseId)
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_enrollment_course ON $tableEnrollment(courseId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_enrollment_student ON $tableEnrollment(studentId)',
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<void> clearAllTables() async {
    final db = await database;
    await db.delete(tableEnrollment);
    await db.delete(tableGrade);
    await db.delete(tableAssessment);
    await db.delete(tableAttendanceRecord);
    await db.delete(tableCourse);
    await db.delete(tableStudent);
    await db.delete(tableUser);
  }
}
