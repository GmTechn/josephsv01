// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:josephs_vs_01/models/tasks.dart';
import 'package:josephs_vs_01/models/users.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseManager {
  static const _dbName = 'josephs.db';
  static const _dbVersion = 3;

  static const _tableUsers = 'users';
  static const _tableTasks = 'tasks';

  static const int _localUserId = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) {
      try {
        await _db!.rawQuery('SELECT 1');
        return _db!;
      } catch (_) {
        _db = null;
      }
    }
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async => _createSchema(db),
      onUpgrade: (db, oldVersion, newVersion) async => _migrate(db),
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableUsers(
        id INTEGER PRIMARY KEY,
        fname TEXT NOT NULL DEFAULT '',
        lname TEXT NOT NULL DEFAULT '',
        photoPath TEXT NOT NULL DEFAULT ''
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_tableTasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'To do',
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        recurrenceType TEXT,
        recurrenceEndDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY(userId) REFERENCES $_tableUsers(id) ON DELETE CASCADE
      );
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_tasks_user_date ON $_tableTasks(userId, date);',
    );

    await db.insert(_tableUsers, {
      'id': _localUserId,
      'fname': '',
      'lname': '',
      'photoPath': '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _migrate(Database db) async {
    await _ensureColumn(
      db,
      _tableUsers,
      'photoPath',
      "TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumn(db, _tableUsers, 'fname', "TEXT NOT NULL DEFAULT ''");
    await _ensureColumn(db, _tableUsers, 'lname', "TEXT NOT NULL DEFAULT ''");

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$_tableTasks'",
    );

    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $_tableTasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          status TEXT NOT NULL DEFAULT 'To do',
          title TEXT NOT NULL,
          subtitle TEXT NOT NULL DEFAULT '',
          date TEXT NOT NULL,
          startTime TEXT,
          endTime TEXT,
          isRecurring INTEGER NOT NULL DEFAULT 0,
          recurrenceType TEXT,
          recurrenceEndDate TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        );
      ''');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_user_date ON $_tableTasks(userId, date);',
      );
    } else {
      await _ensureColumn(db, _tableTasks, 'startTime', 'TEXT');
      await _ensureColumn(db, _tableTasks, 'endTime', 'TEXT');
      await _ensureColumn(
        db,
        _tableTasks,
        'createdAt',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _ensureColumn(
        db,
        _tableTasks,
        'updatedAt',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _ensureColumn(
        db,
        _tableTasks,
        'subtitle',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _ensureColumn(
        db,
        _tableTasks,
        'status',
        "TEXT NOT NULL DEFAULT 'To do'",
      );
      await _ensureColumn(
        db,
        _tableTasks,
        'isRecurring',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await _ensureColumn(db, _tableTasks, 'recurrenceType', 'TEXT');
      await _ensureColumn(db, _tableTasks, 'recurrenceEndDate', 'TEXT');
    }

    await db.insert(_tableUsers, {
      'id': _localUserId,
      'fname': '',
      'lname': '',
      'photoPath': '',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _ensureColumn(
    Database db,
    String table,
    String column,
    String definition,
  ) async {
    final info = await db.rawQuery("PRAGMA table_info($table)");
    final exists = info.any(
      (c) => (c['name'] as String).toLowerCase() == column.toLowerCase(),
    );
    if (!exists) {
      await db.execute("ALTER TABLE $table ADD COLUMN $column $definition");
    }
  }

  Future<void> resetDb() async {
    final path = join(await getDatabasesPath(), _dbName);

    if (_db != null) {
      await _db!.close();
      _db = null;
    }

    if (await File(path).exists()) {
      await deleteDatabase(path);
    }
  }

  Future<AppUser?> getLocalUser() async {
    final db = await database;
    final rows = await db.query(
      _tableUsers,
      where: 'id = ?',
      whereArgs: [_localUserId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<void> updateLocalUser({
    String? fname,
    String? lname,
    String? photoPath,
  }) async {
    final db = await database;

    final current = await getLocalUser();
    final data = <String, Object?>{
      'fname': fname ?? current?.fname ?? '',
      'lname': lname ?? current?.lname ?? '',
      'photoPath': photoPath ?? current?.photoPath ?? '',
    };

    final count = await db.update(
      _tableUsers,
      data,
      where: 'id = ?',
      whereArgs: [_localUserId],
    );

    if (count == 0) {
      await db.insert(_tableUsers, {
        'id': _localUserId,
        ...data,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<int> createTask({
    required String title,
    required String subtitle,
    required DateTime date,
    String status = 'To do',
    String? startTime,
    String? endTime,
    bool isRecurring = false,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert(_tableTasks, {
      'userId': _localUserId,
      'status': status,
      'title': title.trim(),
      'subtitle': subtitle.trim(),
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'isRecurring': isRecurring ? 1 : 0,
      'recurrenceType': isRecurring ? recurrenceType : null,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'createdAt': now,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks({String? status, DateTime? day}) async {
    final db = await database;

    final where = <String>['userId = ?'];
    final args = <Object?>[_localUserId];

    if (status != null && status.isNotEmpty && status != 'All') {
      where.add('status = ?');
      args.add(status);
    }

    if (day != null) {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      where.add('date >= ? AND date < ?');
      args.addAll([start.toIso8601String(), end.toIso8601String()]);
    }

    final rows = await db.query(
      _tableTasks,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'date ASC, startTime ASC, createdAt DESC',
    );

    return rows.map((r) => Task.fromMap(r)).toList();
  }

  Future<void> updateTask({
    required int id,
    String? status,
    String? title,
    String? subtitle,
    DateTime? date,
    String? startTime,
    String? endTime,
    bool? isRecurring,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
  }) async {
    final db = await database;

    final data = <String, Object?>{
      if (status != null) 'status': status,
      if (title != null) 'title': title.trim(),
      if (subtitle != null) 'subtitle': subtitle.trim(),
      if (date != null) 'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      if (isRecurring != null) 'isRecurring': isRecurring ? 1 : 0,
      if (isRecurring != null && isRecurring == false) 'recurrenceType': null,
      if (isRecurring != null && isRecurring == false)
        'recurrenceEndDate': null,
      if (isRecurring == true) 'recurrenceType': recurrenceType,
      if (isRecurring == true)
        'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await db.update(
      _tableTasks,
      data,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, _localUserId],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(
      _tableTasks,
      where: 'id = ? AND userId = ?',
      whereArgs: [id, _localUserId],
    );
  }
}
