import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:english_words/english_words.dart';

class Dog {
  final int? id;
 String name;
  final String breed;
  final String photo;

  Dog({this.id,required this.name, required this.breed, required this.photo});

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
  List<Dog> adoptedDogs = await dogs();
  print(adoptedDogs); // Prints a list that include Fido.


//update
Future<void> updateDog(Dog dog) async {
  final db = await database;
  await db.update(
    'dogs',
    dog.toMap(),
    where: 'id = ?',
    whereArgs: [dog.id],
  );
}

adoptedDogs.shuffle();
Dog luckyDog = adoptedDogs.first;

print("lucky Dog change : ${luckyDog.name}"); // Print name of ClayHall
luckyDog.name = "Jhnna"; // Change the name
print("lucky Dog to new name : ${luckyDog.name}"); // Print new name

// Update the dog in the database
await updateDog(luckyDog);

print("Official Name: ${luckyDog.name}"); // Print updated name


Future<void> deleteDog(int id) async {
  final db = await database;
  await db.delete(
    'dogs',
    where: 'id = ?',
    whereArgs: [id],
  );
}
adoptedDogs.shuffle();
Dog unluckyDog = adoptedDogs.first;

print("unluckyDog change : ${unluckyDog.name}"); // Print name of ClayHall
unluckyDog.name = "Jhnna"; // Change the name
print("unluckyDog to new name : ${unluckyDog.name}"); // Print new name

// Update the dog in the database
await updateDog(unluckyDog);

print("Official Name: ${unluckyDog.name}");


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