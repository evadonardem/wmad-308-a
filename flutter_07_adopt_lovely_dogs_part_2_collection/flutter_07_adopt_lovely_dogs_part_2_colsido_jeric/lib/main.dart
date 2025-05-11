import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for defaultTargetPlatform
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Import for desktop support

void main() {
  // Initialize sqflite for desktop platforms
  if (isDesktop()) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

bool isDesktop() {
  return [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ].contains(defaultTargetPlatform);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dog',
      theme: ThemeData(
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

  Database? _database;

  @override
  void initState() {
    super.initState();
    futureDogs = fetchDogs();
    futureDogs.then((dogs) {
      setState(() {
        filteredDogs = dogs;
      });
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initDatabase();
  }

  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dogs.db');

    _database = await openDatabase(
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
          CREATE TABLE given_dogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            breed TEXT,
            name TEXT,
            imageUrl TEXT
          )
        ''');
      },
    );

    await _loadAdoptedDogs();
    await _loadGivenDogs();
  }

  Future<void> _loadAdoptedDogs() async {
    final data = await _database!.query('adopted_dogs');
    setState(() {
      likedDogs = data
          .map((dog) => Dog(
                breed: dog['breed'] as String,
                name: dog['name'] as String,
                imageUrl: dog['imageUrl'] as String,
              ))
          .toList();
    });
  }

  Future<void> _loadGivenDogs() async {
    final data = await _database!.query('given_dogs');
    setState(() {
      givenDogs = data
          .map((dog) => Dog(
                breed: dog['breed'] as String,
                name: dog['name'] as String,
                imageUrl: dog['imageUrl'] as String,
              ))
          .toList();
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

  void likeDog(Dog? dog) async {
    if (dog == null) {
      print("Error: Dog object is null");
      return; // Exit early if the dog object is null
    }

    print("Dog object: ${dog.name}, ${dog.breed}, ${dog.imageUrl}");

    if (_database == null) {
      await _initDatabase(); // Ensure the database is initialized
    }

    setState(() {
      if (!likedDogs.any((likedDog) =>
          likedDog.imageUrl == dog.imageUrl && likedDog.name == dog.name)) {
        likedDogs.add(dog);
      }
    });

    // Save to database
    await _database!.insert('adopted_dogs', {
      'breed': dog.breed,
      'name': dog.name,
      'imageUrl': dog.imageUrl,
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

  void giveDog(Dog dog) async {
    setState(() {
      likedDogs.remove(dog);
      givenDogs.add(dog);
    });

    // Remove from adopted_dogs and add to given_dogs
    await _database!.insert('given_dogs', {
      'breed': dog.breed,
      'name': dog.name,
      'imageUrl': dog.imageUrl,
    });
  }

  void deleteGivenDog(Dog dog) async {
    setState(() {
      givenDogs.remove(dog);
    });

    // Remove from database
    final data = await _database!.query('given_dogs');
    final dogToDelete = data.firstWhere((d) =>
        d['breed'] == dog.breed &&
        d['name'] == dog.name &&
        d['imageUrl'] == dog.imageUrl);
    await _database!.delete('given_dogs', where: 'id = ?', whereArgs: [dogToDelete['id']]);
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
          padding: const EdgeInsets.only(top: 50.0), // Adjust the top padding here
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Select a Dog",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 255, 255, 255)),
                  ),
                ),
                FutureBuilder<List<Dog>>(
                  future: futureDogs,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: Color(0xFF8D99AE),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 300, // Set the width of the TextField
                            child: Stack(
                              children: [
                                TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: "Type to search...",
                                    hintStyle: TextStyle(color: Colors.white),
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          showDropdown = !showDropdown;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: const Color.fromARGB(255, 255, 255, 255)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    filterDogs(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (showDropdown)
                            Container(
                              width: 300, // Match the width of the TextField
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredDogs.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(filteredDogs[index]
                                        .breed
                                        .toUpperCase(), style: TextStyle(color: Colors.white)),
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
                    return const Text("No dogs found.", style: TextStyle(color: Colors.white));
                  },
                ),
                if (hasSelection)
                  isLoadingImage
                      ? Padding(
                          padding: const EdgeInsets.only(
                              top: 20.0), // Adjust the position to be lower
                          child: const CircularProgressIndicator(
                            color: Color(0xFF8D99AE),
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
                                      width: 250, // Increased width
                                      height: 250, // Increased height
                                      fit: BoxFit.cover, // Ensure the image covers the box
                                    ),
                                  ),
                                  Text(
                                    snapshot.data!.name.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          if (snapshot.data != null) {
                                            likeDog(snapshot.data!);
                                          } else {
                                            print("Error: snapshot.data is null");
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF8D99AE), // Button color
                                          shadowColor: Colors.white,
                                          elevation: 0, // No shadow by default
                                          textStyle: TextStyle(color: Colors.white),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ).copyWith(
                                          elevation: WidgetStateProperty.resolveWith<double>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return 10;
                                              }
                                              return 0;
                                            },
                                          ),
                                          shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                );
                                              }
                                              return RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              );
                                            },
                                          ),
                                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return Color(0xFFB0BEC5);
                                              }
                                              return Color(0xFF8D99AE);
                                            },
                                          ),
                                          overlayColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                // ignore: deprecated_member_use
                                                return Colors.white.withOpacity(0.1);
                                              }
                                              return Colors.transparent;
                                            },
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
                                          backgroundColor: Color(0xFF8D99AE), // Button color
                                          shadowColor: Colors.white,
                                          elevation: 0, // No shadow by default
                                          textStyle: TextStyle(color: Colors.white),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ).copyWith(
                                          elevation: WidgetStateProperty.resolveWith<double>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return 10;
                                              }
                                              return 0;
                                            },
                                          ),
                                          shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                );
                                              }
                                              return RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              );
                                            },
                                          ),
                                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return Color(0xFFB0BEC5);
                                              }
                                              return Color(0xFF8D99AE);
                                            },
                                          ),
                                          overlayColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                // ignore: deprecated_member_use
                                                return Colors.white.withOpacity(0.1);
                                              }
                                              return Colors.transparent;
                                            },
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
      Center(
        child: SizedBox(
          width: double.infinity, // Make the grid take the full width
          child: GridView.builder(
            shrinkWrap: true, // Ensures the grid doesn't take infinite height
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // Number of columns in the grid
              crossAxisSpacing: 10, // Spacing between columns
              mainAxisSpacing: 10, // Spacing between rows
              childAspectRatio: 3 / 4, // Aspect ratio for grid items
            ),
            itemCount: likedDogs.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF8D99AE), // Border color
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          likedDogs[index].imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        likedDogs[index].breed,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        likedDogs[index].name,
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          giveDog(likedDogs[index]);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8D99AE), // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Give Away",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      Center(
        child: SizedBox(
          width: double.infinity, // Make the grid take the full width
          child: GridView.builder(
            shrinkWrap: true, // Ensures the grid doesn't take infinite height
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // Number of columns in the grid
              crossAxisSpacing: 10, // Spacing between columns
              mainAxisSpacing: 10, // Spacing between rows
              childAspectRatio: 3 / 4, // Aspect ratio for grid items
            ),
            itemCount: givenDogs.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF8D99AE), // Border color
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          givenDogs[index].imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        givenDogs[index].breed,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        givenDogs[index].name,
                        style: TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          deleteGivenDog(givenDogs[index]);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF8D99AE), // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Remove",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://example.com/your-profile-picture.jpg'), // Replace with your profile picture URL
              ),
              SizedBox(height: 16),
              Text(
                'colsido jeric',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Dog Lover & Rescuer',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              SizedBox(height: 16),
              Card(
                color: Color(0xFF3b3a30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
'Adopting a dog is one of the most rewarding experiences you can have. Not only does it offer a loving home to an animal in need, but it also brings boundless joy, companionship, and a deeper sense of connection with the world around you.',
style: TextStyle(fontSize: 16, color: Colors.white),
textAlign: TextAlign.left,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Add your contact action here
                },
                icon: Icon(Icons.email, color: Colors.white),
                label: Text('Contact Me', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8D99AE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 78, 93, 255), Color.fromARGB(255, 128, 174, 255)], // Gradient background
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make Scaffold background transparent
        body: _buildPages().elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Adopted'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Give Away Dogs'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'About'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color.fromARGB(255, 65, 119, 253), // Color for the selected item (light color)
          unselectedItemColor: Color(0xFF8D99AE), // Color for unselected items (darker color)
          backgroundColor: Color(0xFF2B2D42), // Background color of the BottomNavigationBar
          showUnselectedLabels: true, // Show labels for unselected items
          onTap: _onItemTapped,
        ),
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