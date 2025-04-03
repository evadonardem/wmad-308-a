import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Flutter Jr Dog',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: Color(0xFFfbf8ef),
          primaryContainer: Color(0xFF0d47a1),
          secondary: Color(0xFF212121),
          secondaryContainer: Color(0xFF0d47a1),
          surface: Color(0xFFfbf8ef),
          error: Colors.red,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.black,
          onError: Colors.black,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Color(0xFFfbf8ef),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dogs.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE adopted_dogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            breed TEXT,
            name TEXT,
            imageUrl TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE giveaway_dogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            breed TEXT,
            name TEXT,
            imageUrl TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertDog(String table, Dog dog) async {
    final db = await database;
    await db.insert(table, {
      'breed': dog.breed,
      'name': dog.name,
      'imageUrl': dog.imageUrl,
    });
  }

  Future<List<Dog>> getDogs(String table) async {
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

  Future<void> deleteDog(String table, Dog dog) async {
    final db = await database;
    await db.delete(
      table,
      where: 'breed = ? AND name = ? AND imageUrl = ?',
      whereArgs: [dog.breed, dog.name, dog.imageUrl],
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Dog>> futureDogs;
  Future<Dog>? futureSelectedDog;
  bool hasSelection = false;
  bool isLoadingImage = false;
  Dog? selectedDog;
  List<Dog> filteredDogs = [];
  TextEditingController searchController = TextEditingController();
  bool showDropdown = false;
  List<Dog> likedDogs = [];
  List<Dog> givenDogs = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    futureDogs = fetchDogs();
    futureDogs.then((dogs) {
      setState(() {
        filteredDogs = dogs;
      });
    });
    _loadAdoptedDogs();
    _loadGivenDogs();
  }

  Future<void> _loadAdoptedDogs() async {
    final dogs = await DatabaseHelper.instance.getDogs('adopted_dogs');
    setState(() {
      likedDogs = dogs;
    });
  }

  Future<void> _loadGivenDogs() async {
    final dogs = await DatabaseHelper.instance.getDogs('giveaway_dogs');
    setState(() {
      givenDogs = dogs;
    });
  }

  void handleDogSelection(Dog dog) {
    setState(() {
      hasSelection = true;
      isLoadingImage = true;
      futureSelectedDog = fetchRandomDogImage(dog.breed).then((dog) {
        setState(() {
          isLoadingImage = false;
          selectedDog = dog;
        });
        return dog;
      });
      showDropdown = false;
      searchController.text = dog.breed.toUpperCase();
    });
  }

  void filterDogs(String query) {
    futureDogs.then((dogs) {
      setState(() {
        filteredDogs = dogs
            .where(
                (dog) => dog.breed.toLowerCase().contains(query.toLowerCase()))
            .toList();
        showDropdown = true;
      });
    });
  }

  void showNotification(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
        margin: EdgeInsets.symmetric(horizontal: 50, vertical: 200),
      ),
    );
  }

  void likeDog(Dog dog) {
    setState(() {
      if (!likedDogs.any((likedDog) =>
          likedDog.imageUrl == dog.imageUrl && likedDog.name == dog.name)) {
        likedDogs.add(dog);
        DatabaseHelper.instance.insertDog('adopted_dogs', dog);
        showNotification("Dog adopted successfully!");
      } else {
        showNotification("You have already adopted this dog!");
      }
    });
  }

  void fetchNextDog() {
    if (selectedDog != null) {
      setState(() {
        isLoadingImage = true;
        futureSelectedDog = fetchRandomDogImage(selectedDog!.breed).then((dog) {
          setState(() {
            isLoadingImage = false;
            selectedDog = dog;
          });
          return dog;
        });
      });
    }
  }

  void giveDog(Dog dog) {
    setState(() {
      likedDogs.remove(dog);
      givenDogs.add(dog);
      DatabaseHelper.instance.deleteDog('adopted_dogs', dog);
      DatabaseHelper.instance.insertDog('giveaway_dogs', dog);
      showNotification("Dog given away successfully!");
    });
  }

  void deleteGivenDog(Dog dog) {
    setState(() {
      givenDogs.remove(dog);
      DatabaseHelper.instance.deleteDog('giveaway_dogs', dog);
      showNotification("Dog removed from giveaway list!");
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages() {
    return [
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Select a Dog",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                FutureBuilder<List<Dog>>(
                  future: futureDogs,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: Color(0xFF0d47a1),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 300,
                            child: Stack(
                              children: [
                                TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: "Type to search...",
                                    hintStyle: TextStyle(color: Colors.black),
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                                      onPressed: () {
                                        setState(() {
                                          showDropdown = !showDropdown;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF0d47a1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFF0d47a1)),
                                    ),
                                  ),
                                  style: TextStyle(color: Colors.black),
                                  onChanged: (value) {
                                    filterDogs(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (showDropdown)
                            Container(
                              width: 300,
                              constraints: BoxConstraints(maxHeight: 200),
                              margin: const EdgeInsets.only(top: 20),
                              alignment: Alignment.center,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredDogs.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(filteredDogs[index]
                                        .breed
                                        .toUpperCase(), style: TextStyle(color: Colors.black)),
                                    onTap: () {
                                      handleDogSelection(filteredDogs[index]);
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    }
                    return const Text("No dogs found.", style: TextStyle(color: Colors.black));
                  },
                ),
                if (hasSelection)
                  isLoadingImage
                      ? Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: const CircularProgressIndicator(
                            color: Color(0xFF0d47a1),
                          ),
                        )
                      : FutureBuilder<Dog>(
                          future: futureSelectedDog,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.network(
                                      snapshot.data!.imageUrl,
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Text(
                                    snapshot.data!.name.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          likeDog(snapshot.data!);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0d47a1),
                                          shadowColor: Colors.black,
                                          elevation: 0,
                                          textStyle: TextStyle(color: Colors.black),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          "Adopt",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: fetchNextDog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0d47a1),
                                          shadowColor: Colors.black,
                                          elevation: 0,
                                          textStyle: TextStyle(color: Colors.black),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          "Next",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          }),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: likedDogs.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              shadowColor: Colors.grey.withOpacity(0.5),
              color: Color(0x80000000),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.network(
                        likedDogs[index].imageUrl,
                        width: double.infinity,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      children: [
                        Text(
                          "Breed: ${_toPascalCase(likedDogs[index].breed)}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "Name: ${_toPascalCase(likedDogs[index].name)}",
                          style: TextStyle(color: Colors.white),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            giveDog(likedDogs[index]);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF8D99AE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Give", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: givenDogs.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              shadowColor: Colors.grey.withOpacity(0.5),
              color: Color(0x80000000),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.network(
                        givenDogs[index].imageUrl,
                        width: double.infinity,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      children: [
                        Text(
                          "Breed: ${_toPascalCase(givenDogs[index].breed)}",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "Name: ${_toPascalCase(givenDogs[index].name)}",
                          style: TextStyle(color: Colors.white),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () {
                            deleteGivenDog(givenDogs[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 16),
              Card(
                color: Color(0x80000000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'The Dog Adoption App connects families with adoptable dogs from shelters and rescues. Users can easily browse dogs by breed, size, and age, and connect with shelters for adoption inquiries. With helpful resources and tips on dog care and training, the app makes adopting a dog simple, safe, and rewarding. Join us in giving dogs a second chance and helping families find their perfect furry companion',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPages().elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Adopted Dogs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Given Dogs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'About '),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFF0d47a1),
        unselectedItemColor: Color(0xFF757575),
        backgroundColor: Color(0xFF424242),
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

class Dog {
  final String breed;
  final String name;
  final String imageUrl;

  Dog({required this.breed, required this.name, required this.imageUrl});

  factory Dog.withRandomName(String breed, String imageUrl) {
    return Dog(
        breed: breed, name: WordPair.random().join(""), imageUrl: imageUrl);
  }
}

Future<List<Dog>> fetchDogs() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Dog> dogs = [];
    for (var breed in data['message'].keys) {
      dogs.add(Dog(breed: breed, name: WordPair.random().join(), imageUrl: ''));
    }
    return dogs;
  } else {
    throw Exception('Failed to fetch dogs');
  }
}

Future<String> fetchRandomDogImageUrl(String breed) async {
  final dogImageEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('Failed to fetch image for breed');
  }
}

Future<Dog> fetchRandomDogImage(String breed) async {
  final imageUrl = await fetchRandomDogImageUrl(breed);
  return Dog.withRandomName(breed, imageUrl);
}

String _toPascalCase(String text) {
  return text.split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
}