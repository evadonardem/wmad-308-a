import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  runApp(const MyApp());
  databaseFactory = databaseFactoryFfi;
}

class Dog {
  String name; // Changed from final to non-final
  final String breed;
  final String imageUrl;

  Dog({required this.name, required this.breed, required this.imageUrl});

  factory Dog.fromJson(String breed, Map<String, dynamic> json) {
    return Dog(
      name: WordPair.random().asPascalCase,
      breed: breed,
      imageUrl: json['message'],
    );
  }

  @override
  String toString() {
    return 'Dog Name: $name, Breed: $breed, Image URL: $imageUrl';
  }
}

Future<List<String>> fetchDogBreeds() async {
  final response = await http.get(
    Uri.parse('https://dog.ceo/api/breeds/list/all'),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data['message'].keys);
  } else {
    throw Exception('Failed to load dog breeds');
  }
}

Future<Dog> fetchRandomDog(String breed) async {
  final response = await http.get(
    Uri.parse('https://dog.ceo/api/breed/$breed/images/random'),
  );
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
    await db.insert(table, {
      'name': dog.name,
      'breed': dog.breed,
      'imageUrl': dog.imageUrl,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Adoption',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 61, 107, 224),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Princess Pet Shop',
      ),
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
    final dog = await fetchRandomDog(breed);
    setState(() {
      selectedDog = dog;
    });
  }

  void _fetchRandomDog() async {
    if (selectedBreed != null) {
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
                      items:
                          snapshot.requireData
                              .map(
                                (breed) => DropdownMenuItem(
                                  value: breed,
                                  child: Text(breed.toUpperCase()),
                                ),
                              )
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
                Image.network(
                  selectedDog!.imageUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                Text(
                  'Dog Name: ${selectedDog!.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchRandomDog,
                  child: const Text('Get Another Dog'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchRandomDog,
                  child: const Text('Adopt Dog'),
                ),
              ],
            ],
          ),
        );
      case 1:
        return FavoritesScreen(
          favorites: appState.favorites,
          appState: appState,
        );
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
      appBar: AppBar(backgroundColor: Colors.blue, title: Text(widget.title)),
      body: _getBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 30, 105, 233),
        unselectedItemColor: const Color.fromARGB(255, 91, 89, 89),
        backgroundColor: Colors.blue,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Adopted Dogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Giveaway',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About Me'),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Dog> favorites;
  final MyAppState appState;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.appState,
  });

  void _editDogName(BuildContext context, Dog dog, MyAppState appState) {
    final TextEditingController controller = TextEditingController(
      text: dog.name,
    );
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
    // Grouping dogs by breed
    final Map<String, List<Dog>> dogsByBreed = {};
    for (var dog in favorites) {
      if (!dogsByBreed.containsKey(dog.breed)) {
        dogsByBreed[dog.breed] = [];
      }
      dogsByBreed[dog.breed]!.add(dog);
    }

    return Scaffold(
      backgroundColor:
          Colors.lightBlue[50], // Set background color for the screen
      body: ListView.builder(
        itemCount: dogsByBreed.length,
        itemBuilder: (context, index) {
          final breed = dogsByBreed.keys.elementAt(index);
          final dogsOfSameBreed = dogsByBreed[breed]!;

          return Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    breed, // Display breed name
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Group dogs of the same breed and display them in a Row or Column
                SingleChildScrollView(
                  // Prevent overflow when using Row
                  scrollDirection:
                      Axis.horizontal, // Allow horizontal scrolling
                  child: Row(
                    children:
                        dogsOfSameBreed.map((dog) {
                          return Padding(
                            padding: const EdgeInsets.all(
                              8.0,
                            ), // Add padding to prevent overflow
                            child: Card(
                              elevation: 4.0,
                              child: Column(
                                children: [
                                  Container(
                                    width: 100, // Fixed width for images
                                    height: 100, // Fixed height for images
                                    child: Image.network(
                                      dog.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _editDogName(context, dog, appState);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.sell),
                                        onPressed: () {
                                          appState.addToGiveaway(dog);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          appState.deleteDog(dog);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GiveawayScreen extends StatelessWidget {
  final List<Dog> giveaway;
  final MyAppState appState;

  const GiveawayScreen({
    super.key,
    required this.giveaway,
    required this.appState,
  });

  void _editDogName(BuildContext context, Dog dog, MyAppState appState) {
    final TextEditingController controller = TextEditingController(
      text: dog.name,
    );
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
    // Grouping dogs by breed
    final Map<String, List<Dog>> dogsByBreed = {};
    for (var dog in giveaway) {
      if (!dogsByBreed.containsKey(dog.breed)) {
        dogsByBreed[dog.breed] = [];
      }
      dogsByBreed[dog.breed]!.add(dog);
    }

    return Scaffold(
      backgroundColor:
          Colors.lightBlue[50], // Set background color for the screen
      body: ListView.builder(
        itemCount: dogsByBreed.length,
        itemBuilder: (context, index) {
          final breed = dogsByBreed.keys.elementAt(index);
          final dogsOfSameBreed = dogsByBreed[breed]!;

          return Card(
            margin: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    breed, // Display breed name
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Group dogs of the same breed and display them in a Row or Column
                // Using Row for horizontal display, change to Column for vertical display
                Row(
                  children:
                      dogsOfSameBreed.map((dog) {
                        return Container(
                          width:
                              120, // Set the width for the individual dog card
                          child: Card(
                            elevation: 4.0,
                            child: Column(
                              children: [
                                Image.network(
                                  dog.imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    dog.name,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () {
                                        _editDogName(context, dog, appState);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        appState.deleteFromGiveaway(dog);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AboutMeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.lightBlue[50], // Changed background color to pale green
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text(
              'Friends Paws',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(
                  255,
                  10,
                  10,
                  10,
                ), // Text color remains teal
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Welcome to Princess Dog Adoption app'
              'Lorem ipsum dolor sit amet consectetur adipiscing elit.'
              'Ex sapien vitae pellentesque sem placerat in id. '
              'Pretium tellus duis convallis tempus leo eu aenean.'
              'Urna tempor pulvinar vivamus fringilla lacus nec metus. Iaculis massa nisl malesuada lacinia integer nunc posuere.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87, // Text color for readability
                height: 1.6,
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}