import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/dog.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'dogs.db'),
      version: 2, // Increment the version number
      onCreate: (db, version) {
        db.execute(
          'CREATE TABLE adopted_dogs(id INTEGER PRIMARY KEY, breed TEXT, name TEXT, imageUrl TEXT)',
        );
        db.execute(
          'CREATE TABLE given_dogs(id INTEGER PRIMARY KEY, breed TEXT, name TEXT, imageUrl TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < 2) {
          db.execute(
            'CREATE TABLE given_dogs(id INTEGER PRIMARY KEY, breed TEXT, name TEXT, imageUrl TEXT)',
          );
        }
      },
    );
  }

  Future<int> insertDog(Dog dog) async {
    final db = await database;
    return await db.insert('adopted_dogs', {
      'breed': dog.breed,
      'name': dog.name,
      'imageUrl': dog.imageUrl,
    });
  }

  Future<List<Dog>> getAdoptedDogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('adopted_dogs');
    return List.generate(maps.length, (i) {
      return Dog(
        id: maps[i]['id'], // Include id
        breed: maps[i]['breed'],
        name: maps[i]['name'],
        imageUrl: maps[i]['imageUrl'],
      );
    });
  }

  Future<int> updateDogName(int id, String newName) async {
    final db = await database;
    return await db.update(
      'adopted_dogs',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteDog(int id) async {
    final db = await database;
    return await db.delete(
      'adopted_dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertGivenDog(Dog dog) async {
    final db = await database;
    return await db.insert('given_dogs', {
      'breed': dog.breed,
      'name': dog.name,
      'imageUrl': dog.imageUrl,
    });
  }

  Future<List<Dog>> getGivenDogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('given_dogs');
    return List.generate(maps.length, (i) {
      return Dog(
        id: maps[i]['id'], // Include id
        breed: maps[i]['breed'],
        name: maps[i]['name'],
        imageUrl: maps[i]['imageUrl'],
      );
    });
  }

  Future<int> deleteDogFromGiven(int id) async {
    final db = await database;
    return await db.delete(
      'given_dogs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}