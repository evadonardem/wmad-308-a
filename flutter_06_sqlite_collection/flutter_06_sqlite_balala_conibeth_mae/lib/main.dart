import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
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
    return 'Dog{id: $id, name: $name, breed: $breed}';
  }
}

Future<void> main() async {
  //open//create database
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();

  final databasePath = await getDatabasesPath();
  print("Database path: $databasePath");

  final database = openDatabase(
    join(await getDatabasesPath(), 'doggie_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY, name TEXT, breed TEXT, photo TEXT)',
      );
    },
    version: 1,
  );

//crud
//create

  Future<void> insertDog(Dog dog) async {
    final db = await database;

    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

//sample create/insert data
// Create a Dog and add it to the dogs table

  for (var i = 0; i < 10; i++) {
    final adoptedDogName = WordPair.random().asPascalCase;
    var adoptedDog =
        Dog(name: adoptedDogName, breed: "askal", photo: "http://some-url");

    await insertDog(adoptedDog);
  }

//read data
// A method that retrieves all the dogs from the dogs table.
  Future<List<Dog>> dogs() async {
    final db = await database;

    final List<Map<String, Object?>> dogMaps = await db.query('dogs');
    return [
      for (final {
            'id': id as int,
            'name': name as String,
            'breed': breed as String,
            'photo': photo as String
          } in dogMaps)
        Dog(id: id, name: name, breed: breed, photo: photo),
    ];
  }

  //sample retrieving all adopted dogs from database
// Now, use the method above to retrieve all the dogs.
  List<Dog> adoptedDogs = await dogs();
  print(await dogs()); 

  Future<void> updateDog(Dog dog) async {
  // Get a reference to the database.
  final db = await database;

  // Update the given Dog.
  await db.update(
    'dogs',
    dog.toMap(),
    where: 'id = ?',
    whereArgs: [dog.id],
  );
}

adoptedDogs.shuffle();
Dog luckyDog = adoptedDogs.first;

print("Lucky dog to your new name: ${luckyDog.name}");
luckyDog.name = "Princess";
updateDog(luckyDog);
print("Lucky dog to your new name:${luckyDog.name}");

//Update thedog Database
await updateDog(luckyDog);

// Delete
Future<void> deleteDog(int id) async {
  final db = await database;

  await db.delete(
    'dogs',
    where: 'id = ?',
    whereArgs: [id],
  );
}

//Sample Delete adopted dog
adoptedDogs.shuffle();
Dog unluckyDog = adoptedDogs.first;
print("Your so unlucky ${unluckyDog.name}");
unluckyDog.name = "Asoni";
deleteDog(unluckyDog.id!);

//Update thedog Database
await updateDog(luckyDog);

  runApp(const MyApp());
}

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
            const Text(
              'You have pushed the button this many times:',
            ),
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