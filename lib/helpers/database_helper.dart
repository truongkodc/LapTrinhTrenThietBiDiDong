import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/exercise.dart';

// =============================================
// DATABASE HELPER - SQLite CRUD (Bài 6 P1)
// =============================================
// Sử dụng sqflite để lưu trữ dữ liệu bài tập
// dạng cơ sở dữ liệu quan hệ (Relational DB).

class DatabaseHelper {
  // Singleton pattern - chỉ tạo 1 instance duy nhất
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Tên database và bảng
  static const String _dbName = 'fitplan_hutech.db';
  static const int _dbVersion = 1;
  static const String tableExercises = 'exercises';

  /// Lấy hoặc khởi tạo database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Khởi tạo database với bảng exercises
  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _createDatabase);
  }

  /// Tạo bảng exercises khi database được tạo lần đầu
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableExercises (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        dayOfWeek TEXT NOT NULL,
        notes TEXT,
        imagePath TEXT,
        isCompleted INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================
  // CRUD OPERATIONS (Bài 6 P1)
  // =========================

  /// CREATE: Thêm bài tập mới vào database
  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    return db.insert(
      tableExercises,
      exercise.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// READ: Lấy tất cả bài tập từ database
  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercises,
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  /// READ: Lấy bài tập theo category
  Future<List<Exercise>> getExercisesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercises,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }

  /// READ: Lấy một bài tập theo ID
  Future<Exercise?> getExerciseById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableExercises,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Exercise.fromMap(maps.first);
    }
    return null;
  }

  /// UPDATE: Cập nhật thông tin bài tập
  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    return db.update(
      tableExercises,
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  /// DELETE: Xóa bài tập theo ID
  Future<int> deleteExercise(String id) async {
    final db = await database;
    return db.delete(tableExercises, where: 'id = ?', whereArgs: [id]);
  }

  /// DELETE ALL: Xóa toàn bộ bài tập
  Future<int> deleteAllExercises() async {
    final db = await database;
    return db.delete(tableExercises);
  }

  /// COUNT: Đếm số bài tập
  Future<int> getExerciseCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableExercises',
    );
    return result.first['count'] as int? ?? 0;
  }

  /// STATISTICS: Lấy tổng calo đã đốt (bài tập hoàn thành)
  Future<int> getTotalCaloriesBurned() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(calories), 0) as total FROM $tableExercises WHERE isCompleted = 1',
    );
    return result.first['total'] as int? ?? 0;
  }

  /// Đóng database
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
