import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}

class Dog {
  final String name;
  final String breed;
  final String imageUrl;

  Dog({required this.name, required this.breed, required this.imageUrl});

  factory Dog.fromJson(Map<String, dynamic> json, String breed) {
    return Dog(
      name: WordPair.random().asPascalCase,
      breed: breed,
      imageUrl: json['message'] as String,
    );
  }
}

Future<List<String>> fetchDogBreeds() async {
  const String url = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data['message'].keys);
  } else {
    throw Exception('Failed to load breeds');
  }
}

Future<Dog> fetchRandomDogByBreed(String breed) async {
  final String url = "https://dog.ceo/api/breed/$breed/images/random";
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return Dog.fromJson(data, breed);
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Adoption App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Dog> _adoptedDogs = [];
  final List<Dog> _givenAwayDogs = []; 

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomePage(onAdopt: _adoptDog),
      AdoptedDogsPage(adoptedDogs: _adoptedDogs, onGiveAway: _giveAwayDog),
      GiveAwayDogsPage(givenAwayDogs: _givenAwayDogs), // Updated to take dogs
      const AboutPage(),
    ]);
  }

  void _adoptDog(Dog dog) {
    setState(() {
      _adoptedDogs.add(dog);
    });
  }

  void _giveAwayDog(Dog dog) {
    setState(() {
      _adoptedDogs.remove(dog);  
      _givenAwayDogs.add(dog);   
      _selectedIndex = 2;        
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
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.black), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets, color: Colors.black), label: 'Adopted'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite, color: Colors.black), label: 'Give Away'),
          BottomNavigationBarItem(icon: Icon(Icons.info, color: Colors.black), label: 'About'),
        ],
      ),
    );
  }
}




class HomePage extends StatefulWidget {
  final Function(Dog) onAdopt;

  const HomePage({Key? key, required this.onAdopt}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<String>>? _breeds;
  Future<Dog>? _dog;
  String? _selectedBreed;
  List<String> _allBreeds = [];

  @override
  void initState() {
    super.initState();
    _breeds = fetchDogBreeds().then((breeds) {
      setState(() {
        _allBreeds = breeds;
      });
      return breeds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adopt A Dog',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Quote Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '"Saving one dog will not change the world, but surely for that one dog, the world will change forever."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Searchable Breed Dropdown
              SizedBox(
                width: 350,
                child: TypeAheadField<String>(
                  textFieldConfiguration: TextFieldConfiguration(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: "Search for a breed",
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  suggestionsCallback: (pattern) {
                    return _allBreeds
                        .where((breed) => breed.toLowerCase().contains(pattern.toLowerCase()))
                        .toList();
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      title: Text(suggestion.toUpperCase()),
                    );
                  },
                  onSuggestionSelected: (String selectedBreed) {
                    setState(() {
                      _selectedBreed = selectedBreed;
                      _dog = fetchRandomDogByBreed(selectedBreed);
                    });
                  },
                ),
              ),

              const SizedBox(height: 25),

              // Dog Image & Details
              FutureBuilder<Dog>(
                future: _dog,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData) {
                    return const Text(
                      "Select a breed to see a dog.",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    );
                  }

                  final dog = snapshot.data!;
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          dog.imageUrl,
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
  "Breed: ${dog.breed.toUpperCase()}",
  style: const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),
const SizedBox(height: 5), // Add spacing between breed and name
Text(
  "Name: ${dog.name}",
  style: const TextStyle(
    fontSize: 18,
    fontStyle: FontStyle.italic,
    color: Colors.blueGrey,
  ),
),

                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.onAdopt(dog);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.favorite, color: Colors.white),
                            label: const Text(
                              "Adopt",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 15),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _dog = fetchRandomDogByBreed(dog.breed);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text("Show Another"),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class AdoptedDogsPage extends StatefulWidget {
  final List<Dog> adoptedDogs;
  final Function(Dog) onGiveAway;

  const AdoptedDogsPage({Key? key, required this.adoptedDogs, required this.onGiveAway})
      : super(key: key);

  @override
  _AdoptedDogsPageState createState() => _AdoptedDogsPageState();
}

class _AdoptedDogsPageState extends State<AdoptedDogsPage> {
  late List<Dog> _dogs;

  @override
  void initState() {
    super.initState();
    _dogs = List.from(widget.adoptedDogs); 
  }

  void _giveAwayDog(Dog dog) {
    setState(() {
      _dogs.remove(dog); 
    });
    widget.onGiveAway(dog); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Adopted Dogs")),
      body: _dogs.isEmpty
          ? const Center(child: Text("No adopted dogs yet."))
          : ListView.builder(
              itemCount: _dogs.length,
              itemBuilder: (context, index) {
                final dog = _dogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: dog.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      dog.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(dog.breed.toUpperCase()),
                    trailing: ElevatedButton(
                      onPressed: () => _giveAwayDog(dog), // Call removal function
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 253, 18, 1),
                      ),
                      child: const Text("Give Away"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}


class GiveAwayDogsPage extends StatelessWidget {
  final List<Dog> givenAwayDogs;

  const GiveAwayDogsPage({Key? key, required this.givenAwayDogs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Given Away Dogs")),
      body: givenAwayDogs.isEmpty
          ? const Center(child: Text("No dogs have been given away yet."))
          : ListView.builder(
              itemCount: givenAwayDogs.length,
              itemBuilder: (context, index) {
                final dog = givenAwayDogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CachedNetworkImage(
                      imageUrl: dog.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(
                      dog.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(dog.breed.toUpperCase()),
                  ),
                );
              },
            ),
    );
  }
}


class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About Me!"),
        centerTitle: true,
      ),
      body: Center( // Ensures everything is centered
        child: SingleChildScrollView( // Prevents overflow
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Vertically centers content
            crossAxisAlignment: CrossAxisAlignment.center, // Horizontally centers content
            children: [
              const Text(
                "Calias Sandra",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "A third-year college student at\n"
                "Kings College of the Philippines,\n"
                "Hoping for a stable job after graduating.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 25),
              const Text(
                "My Adopt-a-Dog Features:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text("✔ Browse dog breeds and view their images", textAlign: TextAlign.center),
                  Text("✔ Adopt a dog and keep track of them", textAlign: TextAlign.center),
                  Text("✔ Give away a dog if you find them a new home", textAlign: TextAlign.center),
                  Text("✔ Learn more about responsible pet ownership", textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                "\"Saving one dog will not change the world, "
                "but surely for that one dog, the world will change forever.\"",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

