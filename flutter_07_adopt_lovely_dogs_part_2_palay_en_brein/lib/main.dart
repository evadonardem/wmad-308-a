import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:english_words/english_words.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

/// Dog Model
class Dog {
  final int? id;
  final String name, breed, imageUrl;
  final String status; // "adopted" or "given_away"

  Dog({this.id, required this.name, required this.breed, required this.imageUrl, required this.status});

  factory Dog.fromJson(Map<String, dynamic> json) => Dog(
        id: json['id'],
        name: json['name'],
        breed: json['breed'],
        imageUrl: json['imageUrl'],
        status: json['status'],
      );

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'breed': breed, 'imageUrl': imageUrl, 'status': status};
  }
}

/// SQLite Database Helper
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'dogs.db'),
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE dogs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            breed TEXT,
            imageUrl TEXT,
            status TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  Future<void> insertDog(Dog dog) async {
    final db = await database;
    await db.insert('dogs', dog.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Dog>> fetchDogs(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dogs', where: 'status = ?', whereArgs: [status]);
    return List.generate(maps.length, (i) => Dog.fromJson(maps[i]));
  }

  Future<void> removeDog(Dog dog) async {
    final db = await database;
    await db.delete('dogs', where: 'imageUrl = ?', whereArgs: [dog.imageUrl]);
  }
}

/// Fetch Breeds from Dog CEO API
Future<List<String>> fetchBreeds() async {
  final res = await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
  if (res.statusCode == 200) {
    return (jsonDecode(res.body)['message'] as Map<String, dynamic>).keys.toList();
  }
  throw Exception('Failed to load breeds');
}

/// Fetch Random Dog Image by Breed
Future<Dog> fetchDog(String breed) async {
  final res = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
  if (res.statusCode == 200) {
    return Dog(
      name: WordPair.random().asPascalCase,
      breed: breed,
      imageUrl: jsonDecode(res.body)['message'],
      status: 'adopted',
    );
  }
  throw Exception('Failed to load dog');
}

/// Main App
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  List<Dog> adoptedDogs = [];
  List<Dog> giveAwayDogs = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    loadDogs();
  }

  void loadDogs() async {
    adoptedDogs = await dbHelper.fetchDogs('adopted');
    giveAwayDogs = await dbHelper.fetchDogs('given_away');
    setState(() {});
  }

  void adoptDog(BuildContext context, Dog dog) async {
    if (!adoptedDogs.any((d) => d.imageUrl == dog.imageUrl)) {
      await dbHelper.insertDog(dog);
      setState(() => adoptedDogs.add(dog));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${dog.name} has been adopted!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
      );
    }
  }

  void giveAwayDog(Dog dog) async {
    await dbHelper.removeDog(dog);
    Dog newDog = Dog(name: dog.name, breed: dog.breed, imageUrl: dog.imageUrl, status: 'given_away');
    await dbHelper.insertDog(newDog);
    setState(() {
      adoptedDogs.remove(dog);
      giveAwayDogs.add(newDog);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange), useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: Text('DOG ADOPTION APP'), backgroundColor: Colors.orange),
        body: [
          HomePage(adoptDog: (dog) => adoptDog(context, dog)),
          DogsPage(dogs: adoptedDogs, title: 'Adopted Dogs', action: giveAwayDog, actionLabel: 'Give Away'),
          DogsPage(dogs: giveAwayDogs, title: 'Given Away Dogs'),
          AboutPage(),
        ][_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopted'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Given Away'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          ],
        ),
      ),
    );
  }
}

/// Home Page
class HomePage extends StatefulWidget {
  final Function(Dog) adoptDog;
  const HomePage({super.key, required this.adoptDog});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedBreed;
  Dog? currentDog;
  List<String> breeds = [];

  @override
  void initState() {
    super.initState();
    fetchBreeds().then((value) => setState(() => breeds = value));
  }

  void getNewDog() async {
    if (selectedBreed != null) {
      Dog newDog = await fetchDog(selectedBreed!);
      setState(() => currentDog = newDog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Dog Adoption App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          DropdownButton<String>(
            value: selectedBreed,
            hint: Text('Select a Breed'),
            isExpanded: true,
            items: breeds.map((breed) => DropdownMenuItem(value: breed, child: Text(breed.toUpperCase()))).toList(),
            onChanged: (value) => setState(() => selectedBreed = value),
          ),
          ElevatedButton(onPressed: getNewDog, child: Text('Show & Next Dog')),
          if (currentDog != null) CachedNetworkImage(imageUrl: currentDog!.imageUrl, height: 200),
        ],
      ),
    );
  }
}

/// About Page
class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('About')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'This is a Dog Adoption App where you can adopt or give away dogs. '
            'Built with Flutter and SQLite for managing data.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Dogs Page
class DogsPage extends StatelessWidget {
  final List<Dog> dogs;
  final String title;
  final Function(Dog)? action;
  final String? actionLabel;

  const DogsPage({
    super.key,
    required this.dogs,
    required this.title,
    this.action,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: dogs.isEmpty
          ? Center(child: Text('No dogs available', style: TextStyle(fontSize: 18)))
          : ListView.builder(
              itemCount: dogs.length,
              itemBuilder: (context, index) {
                final dog = dogs[index];
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: CachedNetworkImage(imageUrl: dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                    title: Text(dog.name),
                    subtitle: Text(dog.breed),
                    trailing: action != null
                        ? ElevatedButton(
                            onPressed: () => action!(dog),
                            child: Text(actionLabel ?? ''),
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
