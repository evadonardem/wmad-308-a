import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:english_words/english_words.dart';

class Dog {
  final id;
  final String name;
  final String breed;
  final String photo;

  Dog({this.id, required this.name, required this.breed, required this.photo});

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'breed': breed, 'photo': photo};
  }

  @override
  String toString() {
    return 'Dog{name: $name, breed: $breed, photo: $photo}';
  }  
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String generateNewName() {
    return WordPair.random().join("");
  }

  databaseFactory = databaseFactoryFfi;

  final database = openDatabase(
    join(await getDatabasesPath(), 'doggie_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, breed TEXT, photo TEXT)',
      );
    },
    version: 1,
  );

  // CREATE
  Future<void> insertDog(Dog dog) async {
    final db = await database;

    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // DOGS FETCHING
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

  // DOGS UPDATER
  Future<void> updateDog(Dog dog) async {
    final db = await database;

    await db.update(
      'dogs',
      dog.toMap(),
      where: 'id = ?',
      whereArgs: [dog.id],
    );
  }

  // DOGS DELETER
  Future<void> deleteDog(int id) async {
    final db = await database;

    await db.delete(
      'dogs',
      where: 'id = ?',
      whereArgs: [id],
    );  
  }

  // DOGS GENERATOR
  // for (var i = 0; i < 10; i++) {
  //   final wordPair = generateNewName();
  //   insertDog(
  //       Dog(name: wordPair, breed: "Aspin", photo: "http://localhost:3000"));
  // }

  // DOGS PRINTER
  final allDogs = await dogs();
  allDogs.forEach((dog) => print('My dog ${dog.name.toUpperCase()} was an ${dog.breed.toUpperCase()}.'));
  final favoriteDogIndex = Random().nextInt(allDogs.length);
  print('');
  print('OVERALL I have ${allDogs.length} dogs, and my favorite was ${allDogs[favoriteDogIndex].name.toUpperCase()}.');

  // DOGS UPDATING
  final toUpdateDogIndex = Random().nextInt(allDogs.length);
  final dogToUpdate = allDogs[toUpdateDogIndex];
  final dogUpdate = Dog(
      id: dogToUpdate.id,
      name: generateNewName(),
      breed: dogToUpdate.breed,
      photo: dogToUpdate.photo);
  await updateDog(dogUpdate);

  final newAllDogs = await dogs();
  print('I do not like ${dogToUpdate.name.toUpperCase()}\'s name so I updated it to ${newAllDogs[20].name.toUpperCase()}.');

  // DOGS DELETING
  final toDeleteDogIndex = Random().nextInt(allDogs.length);
  final dogToDelete = allDogs[toDeleteDogIndex];
  await deleteDog(toDeleteDogIndex);
  print('BUT ${dogToDelete.name.toUpperCase()} was illegaly adopted so I thrown it away!');
  final newAllDogsAfterDelete = await dogs();
  print('NOW I have ${newAllDogsAfterDelete.length} dogs.');

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
