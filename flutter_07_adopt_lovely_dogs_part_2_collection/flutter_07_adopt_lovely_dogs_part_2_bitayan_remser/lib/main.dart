import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


// Database helper class to manage SQLite operations
class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the SQLite database
  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/dog_adoption.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE adopted_dogs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            breed TEXT,
            name TEXT,
            imageUrl TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE given_away_dogs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            breed TEXT,
            name TEXT,
            imageUrl TEXT
          )
        ''');
      },
    );
  }

  // Insert a dog into the database (Adopted or Given Away)
  Future<void> insertDog(String table, Dog dog) async {
    final db = await database;
    await db.insert(table, dog.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Fetch all dogs from a specific table (Adopted or Given Away)
  Future<List<Dog>> fetchDogs(String table) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(table);

    return List.generate(maps.length, (i) {
      return Dog(
        breed: maps[i]['breed'],
        name: maps[i]['name'],
        imageUrl: maps[i]['imageUrl'],
      );
    });
  }

  // Delete a dog from the database (Used for "Give Away" action)
  Future<void> deleteDog(String table, int id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}

class Dog {
  final String breed;
  final String name;
  final String imageUrl;

  Dog({required this.breed, required this.name, required this.imageUrl});

  Map<String, dynamic> toMap() {
    return {
      'breed': breed,
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // For desktop support
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Dog> _adoptedDogs = [];
  final List<Dog> _givenAwayDogs = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Adoption App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainScreen(
        adoptedDogs: _adoptedDogs,
        givenAwayDogs: _givenAwayDogs,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final List<Dog> adoptedDogs;
  final List<Dog> givenAwayDogs;

  const MainScreen({
    super.key,
    required this.adoptedDogs,
    required this.givenAwayDogs,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(adoptedDogs: widget.adoptedDogs),
      AdoptedDogsPage(
        adoptedDogs: widget.adoptedDogs,
        givenAwayDogs: widget.givenAwayDogs,
      ),
      GivenAwayDogsPage(givenAwayDogs: widget.givenAwayDogs),
      const AboutPage(),
    ];

    // Initialize DatabaseHelper and load data
    _loadDogsFromDatabase();
  }

  Future<void> _loadDogsFromDatabase() async {
    final dbHelper = DatabaseHelper();

    // Load adopted dogs from SQLite
    final adoptedDogs = await dbHelper.fetchDogs('adopted_dogs');
    setState(() {
      widget.adoptedDogs.addAll(adoptedDogs);
    });

    // Load given away dogs from SQLite
    final givenAwayDogs = await dbHelper.fetchDogs('given_away_dogs');
    setState(() {
      widget.givenAwayDogs.addAll(givenAwayDogs);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopted'),
          BottomNavigationBarItem(icon: Icon(Icons.replay), label: 'Given Away'),
          BottomNavigationBarItem(icon: Icon(Icons.question_mark), label: 'About'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<Dog> adoptedDogs;

  const HomePage({super.key, required this.adoptedDogs});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedBreed;
  String? _dogImage;
  String _randomName = WordPair.random().asPascalCase;
  List<String> _breeds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  Future<void> _loadBreeds() async {
    setState(() => _isLoading = true);
    final response =
        await http.get(Uri.parse("https://dog.ceo/api/breeds/list/all"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _breeds = List<String>.from(data['message'].keys);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load dog breeds');
    }
  }

  Future<void> _fetchBreedImage(String breed) async {
    final response = await http
        .get(Uri.parse("https://dog.ceo/api/breed/$breed/images/random"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _dogImage = data['message'];
        _randomName = WordPair.random().asPascalCase;
      });
    } else {
      throw Exception('Failed to load dog image');
    }
  }

  void _adoptDog() {
    if (_selectedBreed != null && _dogImage != null) {
      setState(() {
        widget.adoptedDogs.add(Dog(
            breed: _selectedBreed!, name: _randomName, imageUrl: _dogImage!));

        // Save the dog to SQLite
        DatabaseHelper().insertDog('adopted_dogs', widget.adoptedDogs.last);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dog Adopted!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20), // Spacing from the top
          const Text(
            'Home',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10), // Spacing below the title
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DropdownButton<String>(
                          value: _selectedBreed,
                          hint: const Text('Select a Dog Breed'),
                          onChanged: (String? breed) {
                            setState(() => _selectedBreed = breed);
                            if (breed != null) {
                              _fetchBreedImage(breed);
                            }
                          },
                          items: _breeds.map((breed) {
                            return DropdownMenuItem<String>(
                              value: breed,
                              child: Text(breed.toUpperCase()),
                            );
                          }).toList(),
                        ),
                        if (_dogImage != null) ...[
                          const SizedBox(height: 20),
                          Image.network(_dogImage!,
                              width: 300, height: 300, fit: BoxFit.cover),
                          const SizedBox(height: 10),
                          Text('Name: $_randomName',
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                  onPressed: _adoptDog, child: const Text("Adopt")),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () => _fetchBreedImage(_selectedBreed!),
                                child: const Text("Show Next"),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdoptedDogsPage extends StatefulWidget {
  final List<Dog> adoptedDogs;
  final List<Dog> givenAwayDogs;

  const AdoptedDogsPage({super.key, required this.adoptedDogs, required this.givenAwayDogs});

  @override
  State<AdoptedDogsPage> createState() => _AdoptedDogsPageState();
}

class _AdoptedDogsPageState extends State<AdoptedDogsPage> {
void _giveAwayDog(int index) async {
  final dog = widget.adoptedDogs[index];
  await DatabaseHelper().insertDog('given_away_dogs', dog);
  await DatabaseHelper().deleteDog('adopted_dogs', index);

  setState(() {
    widget.givenAwayDogs.add(dog);
    widget.adoptedDogs.removeAt(index);
  });
}

void _deleteDog(int index) async {
  await DatabaseHelper().deleteDog('adopted_dogs', index);
  setState(() {
    widget.adoptedDogs.removeAt(index);
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Adopted Dogs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: widget.adoptedDogs.length,
                itemBuilder: (context, index) {
                  final dog = widget.adoptedDogs[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              dog.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dog.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  dog.breed,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _giveAwayDog(index),
                            child: const Text(
                              "Give Away",
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),

                          TextButton(
                            onPressed: () => _deleteDog(index),
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GivenAwayDogsPage extends StatefulWidget {
  final List<Dog> givenAwayDogs;

  const GivenAwayDogsPage({super.key, required this.givenAwayDogs});

  @override
  State<GivenAwayDogsPage> createState() => _GivenAwayDogsPageState();
}

class _GivenAwayDogsPageState extends State<GivenAwayDogsPage> {
  void _deleteDog(int index) async {
    await DatabaseHelper().deleteDog('given_away_dogs', index);
    setState(() {
      widget.givenAwayDogs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Given Away Dogs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: widget.givenAwayDogs.length,
                itemBuilder: (context, index) {
                  final dog = widget.givenAwayDogs[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              dog.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dog.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  dog.breed,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteDog(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/*class GivenAwayDogsPage extends StatelessWidget {
  final List<Dog> givenAwayDogs;

  const GivenAwayDogsPage({super.key, required this.givenAwayDogs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Given Away Dogs',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ListView.builder(
                itemCount: givenAwayDogs.length,
                itemBuilder: (context, index) {
                  final dog = givenAwayDogs[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              dog.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dog.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  dog.breed,
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
*/

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'About',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'My name is Remser Bitayan, 21 years old. 3rd Year BSIT student at Kings College of the Philippines.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}