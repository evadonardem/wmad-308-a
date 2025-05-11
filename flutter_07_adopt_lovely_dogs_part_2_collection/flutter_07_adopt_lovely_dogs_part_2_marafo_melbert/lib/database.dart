import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

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

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        breed TEXT,
        age INTEGER,
        imageUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE adopted_dogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        breed TEXT,
        age INTEGER,
        imageUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE giveaway_dogs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        breed TEXT,
        age INTEGER,
        imageUrl TEXT
      )
    ''');
  }

  Future<int> addDog(Dog dog, String table) async {
    final db = await instance.database;
    return await db.insert(table, dog.toMap());
  }

  Future<List<Dog>> getDogs(String table) async {
    final db = await instance.database;
    final result = await db.query(table);
    return result.map((json) => Dog.fromMap(json)).toList();
  }

  Future<int> deleteDog(int id, String table) async {
    final db = await instance.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> moveDog(int id, String fromTable, String toTable) async {
    final db = await instance.database;
    final dogData = await db.query(fromTable, where: 'id = ?', whereArgs: [id]);

    if (dogData.isNotEmpty) {
      final dog = Dog.fromMap(dogData.first);
      await addDog(dog, toTable);
      await deleteDog(id, fromTable);
    }
  }

  Future<List<Dog>> getAllDogs() async {
    return await getDogs('dogs');
  }

  Future<List<Dog>> getAdoptedDogs() async {
    return await getDogs('adopted_dogs');
  }

  Future<List<Dog>> getGiveAwayDogs() async {
    return await getDogs('giveaway_dogs');
  }

 Future<void> adoptDog(Dog dog) async {
    final db = await instance.database;

    await db.insert('adopted_dogs', dog.toMap());

    if (dog.id != null) {
      await db.delete('dogs', where: 'id = ?', whereArgs: [dog.id]);
    }
  }

  Future<void> giveAwayDog(Dog dog) async {
    final db = await instance.database;

    await db.insert('giveaway_dogs', dog.toMap());

    if (dog.id != null) {
      await db.delete('adopted_dogs', where: 'id = ?', whereArgs: [dog.id]);
    }
  }

  Future<void> removeGiveAwayDog(Dog dog) async {
    await deleteDog(dog.id!, 'giveaway_dogs');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}