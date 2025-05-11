import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:english_words/english_words.dart';


class Dog {
  final String name;
  final String breed;
  final String photo;

  Dog({required this.name, required this.breed, required this.photo});
  
  get id => null;

  Map<String, Object?> toMap() {
    return {'name': name, 'breed': breed, 'photo': photo};
  }

  @override
  String toString() {
    return 'Dog{, name: $name, breed: $breed, photo: $photo}';
  }
}

void main() async {
  databaseFactory = databaseFactoryFfi;

  WidgetsFlutterBinding.ensureInitialized();

  final database = openDatabase(
    join(await getDatabasesPath(), 'doggie_database.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, breed TEXT, photo TEXT)',
      );
    },

    version: 1,
  );

  //create

  Future<void> insertDog(Dog dog) async {
    final db = await database;

    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  for (var i = 0;i <10;i++){
    final adoptedDogName = WordPair.random().asPascalCase;
    final adoptedDogBreed = WordPair.random().asPascalCase;
var adoptedDog = Dog(name: adoptedDogName, breed: adoptedDogBreed, photo: '');

  await insertDog(adoptedDog);
  }
  
//read

Future<List<Dog>> dogs() async {
  final db = await database;

  final List<Map<String, Object?>> dogMaps = await db.query('dogs');

  return [
    for (final {'name': name as String, 'breed': breed as String, 'photo': photo as String}
        in dogMaps)
      Dog( name: name, breed: breed, photo: photo),
  ];
}
print(await dogs());


//update

Future<void> updateDog(Dog dog) async {
  // Get a reference to the database.
  final db = await database;

  // Update the given Dog.
  await db.update(
    'dogs',
    dog.toMap(),
    // Ensure that the Dog has a matching id.
    where: 'id = ?',
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [dog.id],
  );
}

//delete

Future<void> deleteDog(int id) async {
  // Get a reference to the database.
  final db = await database;

  // Remove the Dog from the database.
  await db.delete(
    'dogs',
    // Use a `where` clause to delete a specific dog.
    where: 'id = 1',
    // Pass the Dog's id as a whereArg to prevent SQL injection.
    whereArgs: [id],
  );
}

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
