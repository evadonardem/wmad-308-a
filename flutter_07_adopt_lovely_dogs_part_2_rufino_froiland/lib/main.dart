import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  runApp(const MyApp());
  databaseFactory = databaseFactoryFfi;
}

class Dog {
  String name;
  final String breed;
  final String imageUrl;

  Dog({required this.name, required this.breed, required this.imageUrl});

  factory Dog.fromJson(String breed, Map<String, dynamic> json) {
    return Dog(name: WordPair.random().asPascalCase, breed: breed, imageUrl: json['message']);
  }

  @override
  String toString() {
    return 'Dog Name: $name, Breed: $breed, Image URL: $imageUrl';
  }
}

Future<List<String>> fetchDogBreeds() async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data['message'].keys);
  } else {
    throw Exception('Failed to load dog breeds');
  }
}

Future<Dog> fetchRandomDog(String breed) async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    Dog dog = Dog.fromJson(breed, data);
    return dog;
  } else {
    throw Exception('Failed to load dog image');
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dogs.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE adopted_dogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            breed TEXT,
            imageUrl TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE giveaway_dogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            breed TEXT,
            imageUrl TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertDog(String table, Dog dog) async {
    final db = await database;
    await db.insert(
      table,
      {'name': dog.name, 'breed': dog.breed, 'imageUrl': dog.imageUrl},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDog(String table, Dog dog) async {
    final db = await database;
    await db.delete(
      table,
      where: 'name = ? AND breed = ? AND imageUrl = ?',
      whereArgs: [dog.name, dog.breed, dog.imageUrl],
    );
  }

  Future<List<Dog>> getDogs(String table) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(table);
    return List.generate(maps.length, (i) {
      return Dog(
        name: maps[i]['name'],
        breed: maps[i]['breed'],
        imageUrl: maps[i]['imageUrl'],
      );
    });
  }

  Future<void> updateDogName(String table, Dog dog, String newName) async {
    final db = await database;
    await db.update(
      table,
      {'name': newName},
      where: 'name = ? AND breed = ? AND imageUrl = ?',
      whereArgs: [dog.name, dog.breed, dog.imageUrl],
    );
  }
}

class ConflictAlgorithm {
  static var replace;
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  final DatabaseHelper dbHelper = DatabaseHelper();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <Dog>[];
  var giveaway = <Dog>[];

  MyAppState() {
    _loadDogs();
  }

  void _loadDogs() async {
    favorites = await dbHelper.getDogs('adopted_dogs');
    giveaway = await dbHelper.getDogs('giveaway_dogs');
    notifyListeners();
  }

  void toggleFavorite(Dog dog) async {
    if (favorites.contains(dog)) {
      favorites.remove(dog);
      await dbHelper.deleteDog('adopted_dogs', dog);
    } else {
      favorites.add(dog);
      await dbHelper.insertDog('adopted_dogs', dog);
    }
    notifyListeners();
  }

  bool isFavorite(Dog dog) {
    return favorites.contains(dog);
  }

  void addToGiveaway(Dog dog) async {
    if (!giveaway.contains(dog)) {
      giveaway.add(dog);
      favorites.remove(dog);
      await dbHelper.insertDog('giveaway_dogs', dog);
      await dbHelper.deleteDog('adopted_dogs', dog);
    }
    notifyListeners();
  }

  void deleteDog(Dog dog) async {
    favorites.remove(dog);
    await dbHelper.deleteDog('adopted_dogs', dog);
    notifyListeners();
  }

  void deleteFromGiveaway(Dog dog) async {
    giveaway.remove(dog);
    await dbHelper.deleteDog('giveaway_dogs', dog);
    notifyListeners();
  }

  void updateDogName(Dog dog, String newName) async {
    if (favorites.contains(dog)) {
      await dbHelper.updateDogName('adopted_dogs', dog, newName);
      dog.name = newName;
    } else if (giveaway.contains(dog)) {
      await dbHelper.updateDogName('giveaway_dogs', dog, newName);
      dog.name = newName;
    }
    notifyListeners();
  }
}

class WordPair {
  static random() {}
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkTheme = false;

  void _toggleTheme(bool isDark) {
    setState(() {
      _isDarkTheme = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      home: MyHomePage(title: 'Adopt a dog', toggleTheme: _toggleTheme, isDarkTheme: _isDarkTheme),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.toggleTheme, required this.isDarkTheme});
  final String title;
  final Function(bool) toggleTheme;
  final bool isDarkTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Dog? selectedDog;
  String? selectedBreed;
  late Future<List<String>> futureDogBreeds;
  final MyAppState appState = MyAppState();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void _fetchDogByBreed(String breed) async {
    setState(() {
      selectedDog = null;
    });
    final dog = await fetchRandomDog(breed);
    setState(() {
      selectedDog = dog;
    });
  }

  void _fetchRandomDog() async {
    if (selectedBreed != null) {
      setState(() {
        selectedDog = null;
      });
      final dog = await fetchRandomDog(selectedBreed!);
      setState(() {
        selectedDog = dog;
      });
    }
  }

  void _addToFavorites() {
    if (selectedDog != null) {
      appState.toggleFavorite(selectedDog!);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder(
                future: futureDogBreeds,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return DropdownButton<String>(
                      hint: const Text('Choose a breed'),
                      value: selectedBreed,
                      items: snapshot.requireData
                          .map((breed) => DropdownMenuItem(
                                value: breed,
                                child: Text(breed.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBreed = newValue;
                        });
                        _fetchDogByBreed(newValue!);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 20),
              if (selectedDog != null) ...[
                Expanded(
                  child: Image.network(
                    selectedDog!.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dog Name: ${selectedDog!.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchRandomDog,
                  child: const Text('Get Another Random Dog'),
                ),
                const SizedBox(height: 20),
                IconButton(
                  icon: Icon(
                    appState.isFavorite(selectedDog!) ? Icons.favorite : Icons.favorite_border,
                    color: appState.isFavorite(selectedDog!) ? Colors.red : Colors.grey,
                  ),
                  onPressed: _addToFavorites,
                  iconSize: 40,
                ),
              ] else if (selectedBreed != null) ...[
                const CircularProgressIndicator(),
              ],
            ],
          ),
        );
      case 1:
        return FavoritesScreen(favorites: appState.favorites, appState: appState);
      case 2:
        return GiveawayScreen(giveaway: appState.giveaway, appState: appState);
      case 3:
        return AboutMeScreen();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(widget.title),
        actions: [
          Switch(
            value: widget.isDarkTheme,
            onChanged: widget.toggleTheme,
          ),
        ],
      ),
      body: _getBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blue,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Adopted Dogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Giveaway',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About Me',
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Dog> favorites;
  final MyAppState appState;

  const FavoritesScreen({super.key, required this.favorites, required this.appState});

  void _editDogName(BuildContext context, Dog dog, MyAppState appState) {
    final TextEditingController controller = TextEditingController(text: dog.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Dog Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appState.updateDogName(dog, controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 3,
      childAspectRatio: 1, // Aspect ratio of 1:1
      children: favorites.map((dog) {
        return Card(
          child: GridTile(
            header: GridTileBar(
              backgroundColor: Colors.black54,
              title: Text(
                dog.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Breed: ${dog.breed}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                dog.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            footer: GridTileBar(
              backgroundColor: Colors.black54,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 30),
                    onPressed: () {
                      _editDogName(context, dog, appState);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.sell, color: Colors.white, size: 30),
                    onPressed: () {
                      appState.addToGiveaway(dog);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 30),
                    onPressed: () {
                      appState.deleteDog(dog);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class GiveawayScreen extends StatelessWidget {
  final List<Dog> giveaway;
  final MyAppState appState;

  const GiveawayScreen({super.key, required this.giveaway, required this.appState});

  void _editDogName(BuildContext context, Dog dog, MyAppState appState) {
    final TextEditingController controller = TextEditingController(text: dog.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Dog Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appState.updateDogName(dog, controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 3,
      childAspectRatio: 1,
      children: giveaway.map((dog) {
        return Card(
          child: GridTile(
            header: GridTileBar(
              backgroundColor: Colors.black54,
              title: Text(
                dog.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Breed: ${dog.breed}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.network(
                dog.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            footer: GridTileBar(
              backgroundColor: Colors.black54,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 30),
                    onPressed: () {
                      _editDogName(context, dog, appState);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 30),
                    onPressed: () {
                      appState.deleteFromGiveaway(dog);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class AboutMeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text(
            'Dudz Adopt a Dog',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'This app showcases adoption for dogs. You can choose a dog you want to adopt and if youre tired of them you can give them away!!!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            ' Additionally, the app has been enhanced with a database to track adopted and given-away dogs.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}