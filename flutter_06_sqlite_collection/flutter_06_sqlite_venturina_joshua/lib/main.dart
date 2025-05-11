import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:english_words/english_words.dart';

class Dog {
  int? id;
  String pangalan;
  String lahi;
  String picture;

  Dog(
      {this.id,
      required this.pangalan,
      required this.lahi,
      required this.picture});

  Map<String, Object?> toMap() {
    return {'id': id, 'name': pangalan, 'breed': lahi, 'photo': picture};
  }

  @override
  String toString() {
    return 'Dog{Dog ID: $id, Name: $pangalan, Breed: $lahi, URL: $picture}';
  }
}

void main() async {
  // Database Path
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();

  final databasePath = await getDatabasesPath();
  print("Database Path: $databasePath");

  final database = openDatabase(
    join(databasePath, 'doggie_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, breed TEXT, photo TEXT)',
      );
    },
    version: 1,
  );

  // CRUD Create
  Future<void> insertDog(Dog dog) async {
    final db = await database;

    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  for (var i = 0; i < 10; i++) {
    final adoptedDogName = WordPair.random().asPascalCase;
    var adoptedDog = Dog(
      pangalan: adoptedDogName,
      lahi: 'Askal',
      picture: 'http://some-url',
    );
    await insertDog(adoptedDog);
  }

  // CRUD Read
  Future<List<Dog>> dogs() async {
    final db = await database;
    final List<Map<String, Object?>> dogMaps = await db.query('dogs');

    return [
      for (final {
            'id': id as int,
            'pangalan': name as String,
            'lahi': breed as String,
            'picture': photo as String,
          } in dogMaps)
        Dog(id: id, pangalan: name, lahi: breed, picture: photo),
    ];
  }

  // CRUD Retrieve
  List<Dog> adoptedDogs = await dogs();
  print(adoptedDogs);

  // CRUD Update
  Future<void> updateDog(Dog dog) async {
    final db = await database;

    await db.update(
      'dogs',
      dog.toMap(),
      where: 'id = ?',
      whereArgs: [dog.id],
    );
  }

  // Sample of Update
  adoptedDogs.shuffle();
  Dog luckyDog = adoptedDogs.first;

  print("Lucky dog to change the name: $luckyDog");
  luckyDog.pangalan = "AsteroidDestroyer";
  print("Lucky dog new name: ${luckyDog.pangalan}");
  updateDog(luckyDog);
  print("Lucky dog Registed Name");

  Future<void> deleteDog(int? id) async {
    final db = await database;

    await db.delete('dogs', where: 'id = ?', whereArgs: [id]);
  }

  adoptedDogs.shuffle();
  Dog unluckyDog = adoptedDogs.first;

  print("Unlucky DOG: $unluckyDog");
  deleteDog(unluckyDog.id);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 75, 174, 231)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

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
            const Text('You have pushed the button this many times:'),
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
