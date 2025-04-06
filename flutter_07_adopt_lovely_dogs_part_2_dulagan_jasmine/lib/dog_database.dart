import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'main.dart'; // Make sure this has your Dog model

class DogDatabase {
  static final DogDatabase instance = DogDatabase._init();

  static Database? _database;

  DogDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dogs.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE dogs (
        id $idType,
        name $textType,
        gender $textType,
        birthDate $textType,
        imageUrl $textType,
        breed $textType,
        status $textType
      )
    ''');
  }

  Future<int> createDog(Dog dog, String status) async {
    final db = await instance.database;

    final data = {
      'name': dog.name,
      'gender': dog.gender,
      'birthDate': dog.birthDate.toIso8601String(),
      'imageUrl': dog.imageUrl,
      'breed': dog.breed,
      'status': status, // 'adopted' or 'giveaway'
    };

    return await db.insert('dogs', data);
  }

  Future<List<Dog>> getDogsByStatus(String status) async {
    final db = await instance.database;
    final result = await db.query('dogs', where: 'status = ?', whereArgs: [status]);

    return result.map((json) => Dog(
      name: json['name'] as String,
      gender: json['gender'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      imageUrl: json['imageUrl'] as String,
      breed: json['breed'] as String,
    )).toList();
  }

  Future<void> updateDogStatus(Dog dog, String newStatus) async {
    final db = await instance.database;

    await db.update(
      'dogs',
      {'status': newStatus},
      where: 'name = ? AND imageUrl = ?',
      whereArgs: [dog.name, dog.imageUrl],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
