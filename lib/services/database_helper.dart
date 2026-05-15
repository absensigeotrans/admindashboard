import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('geo_attend.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabel absensi offline
    await db.execute('''
      CREATE TABLE pending_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        check_in_time TEXT,
        check_in_latitude REAL,
        check_in_longitude REAL,
        check_out_time TEXT,
        check_out_latitude REAL,
        check_out_longitude REAL,
        is_mocked INTEGER DEFAULT 0,
        distance_from_office REAL,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        unique_check_in TEXT
      )
    ''');

    // Tabel sinkronisasi absensi
    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        action TEXT NOT NULL,
        record_id TEXT,
        data TEXT,
        sync_status TEXT DEFAULT 'pending',
        error_message TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        synced_at TEXT
      )
    ''');

    // Tabel koneksi terakhir
    await db.execute('''
      CREATE TABLE app_state (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // ─── Pending Attendance CRUD ───

  Future<int> insertPendingAttendance(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pending_attendance', {
      ...data,
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingAttendances() async {
    final db = await database;
    return await db.query(
      'pending_attendance',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllPending() async {
    final db = await database;
    return await db.query(
      'pending_attendance',
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updatePendingAttendance(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'pending_attendance',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAttendanceSynced(int id) async {
    final db = await database;
    return await db.update(
      'pending_attendance',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markAttendanceFailed(int id, String error) async {
    final db = await database;
    return await db.update(
      'pending_attendance',
      {'sync_status': 'failed', 'error_message': error},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSyncedAttendance() async {
    final db = await database;
    return await db.delete(
      'pending_attendance',
      where: 'sync_status = ?',
      whereArgs: ['synced'],
    );
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM pending_attendance WHERE sync_status = 'pending'",
    );
    return result.first['count'] as int;
  }

  // ─── Sync Log ───

  Future<int> insertSyncLog(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('sync_log', {
      ...data,
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getFailedSyncLogs() async {
    final db = await database;
    return await db.query(
      'sync_log',
      where: 'sync_status = ?',
      whereArgs: ['failed'],
    );
  }

  Future<int> retryFailedSync(int id) async {
    final db = await database;
    return await db.update(
      'sync_log',
      {'sync_status': 'pending', 'error_message': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── App State ───

  Future<void> setState(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_state',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getState(String key) async {
    final db = await database;
    final result = await db.query(
      'app_state',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  // ─── Utility ───

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('pending_attendance');
    await db.delete('sync_log');
  }
}
