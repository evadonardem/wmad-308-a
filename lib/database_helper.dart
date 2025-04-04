import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> _initializeDB() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dogs.db');
    print("Database Path: $path");

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE dogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imageUrl TEXT,
            status TEXT
          )
        ''');
        print("Dogs table created");
      },
    );
  }

  // **Create**: Insert a dog record into the database
  static Future<int> insertDog(Map<String, dynamic> dog) async {
    final db = await _initializeDB();
    return await db.insert(
      'dogs',
      dog,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // **Read**: Fetch all dog records from the database
  static Future<List<Map<String, dynamic>>> fetchDogs() async {
    final db = await _initializeDB();
    return await db.query('dogs');
  }

  // **Update**: Update a dog's status in the database
  static Future<int> updateDog(Map<String, dynamic> dog, int id) async {
    final db = await _initializeDB();
    return await db.update(
      'dogs',
      dog,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // **Delete**: Delete a dog record from the database
  static Future<int> deleteDog(int id) async {
    final db = await _initializeDB();
    return await db.delete(
      'dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // **Close Database**
  static Future<void> close() async {
    final db = await _initializeDB();
    await db.close();
  }
}
