import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:english_words/english_words.dart';


class Dog {
  int? id;
  String name;
  String breed;
  String photo;

  Dog({this.id, required this.name, required this.breed, required this.photo});


  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'breed': breed, 'photo': photo};
  }

  @override
  String toString() {
    return 'Dog{Dog ID: $id, Name: $name, Breed: $breed, URL: $photo}';
  }
}

void main() async {
  // Initialize database for Flutter apps using ffi
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();

  // Get database storage location
  final databasePath = await getDatabasesPath();
  print("Database Path: $databasePath");

  // Open or create a database
  final database = openDatabase(
    join(databasePath, 'doggie_database.db'),
    onCreate: (db, version) {
      // Create the "dogs" table in the database
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, breed TEXT, photo TEXT)',
      );
    },
    version: 1,
  );

  // Insert a new dog into the database
  Future<void> insertDog(Dog dog) async {
    final db = await database;
    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Generate and insert sample dog data
  for (var i = 0; i < 10; i++) {
    final adoptedDogName = WordPair.random().asPascalCase;
    var adoptedDog = Dog(
      name: adoptedDogName,
      breed: 'Askal',
      photo: 'http://some-url',
    );
    await insertDog(adoptedDog);
  }

  // Fetch all dogs from the database
  Future<List<Dog>> dogs() async {
    final db = await database;
    final List<Map<String, Object?>> dogMaps = await db.query('dogs');
    return [
      for (final {
            'id': id as int,
            'name': name as String,
            'breed': breed as String,
            'photo': photo as String,
          }
          in dogMaps)
        Dog(id: id, name: name, breed: breed, photo: photo),
    ];
  }

  // Retrieve list of adopted dogs
  List<Dog> adoptedDogs = await dogs();
  print(adoptedDogs);

  // Update an existing dog's information
  Future<void> updateDog(Dog dog) async {
    final db = await database;
    await db.update('dogs', dog.toMap(), where: 'id = ?', whereArgs: [dog.id]);
  }

  // Select a random dog to update its name
  adoptedDogs.shuffle();
  Dog luckyDog = adoptedDogs.first;

  print("Selected dog for name change: $luckyDog");
  luckyDog.name = "Pacalso";
  print("Updated dog's new name: ${luckyDog.name}");
  updateDog(luckyDog);
  print("Dog name updated successfully");

  // Delete a dog from the database
  Future<void> deleteDog(int? id) async {
    final db = await database;
    await db.delete('dogs', where: 'id = ?', whereArgs: [id]);
  }

  // Select a random dog to delete
  adoptedDogs.shuffle();
  Dog unluckyDog = adoptedDogs.first;

  print("Dog selected for removal: $unluckyDog");
  deleteDog(unluckyDog.id);

  runApp(const MyApp());
}

// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

// Stateful widget for home page
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// State class managing the counter functionality
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // Increment the counter when the button is pressed
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pressed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
