import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('adopted_dogs.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        breed TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        adoptedDate TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertDog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('dogs', row);
  }

  Future<List<Map<String, dynamic>>> queryAllDogs() async {
    final db = await instance.database;
    return await db.query('dogs');
  }

  Future<int> updateDog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.update(
      'dogs',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteDog(int id) async {
    final db = await instance.database;
    return await db.delete(
      'dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}