import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class Dog {
  final String name;
  final String imageUrl;

  Dog({required this.name, required this.imageUrl});

  factory Dog.fromJson(WordPair name, Map<String, dynamic> json) {
    return Dog(name: name.asPascalCase, imageUrl: json['message']);
  }

  @override
  String toString() {
    return 'Dog Name: $name, Image URL: $imageUrl';
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

Future<Dog> fetchDog(String breed) async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    WordPair dogName = WordPair.random();
    Dog dog = Dog.fromJson(dogName, data);
    print(dog);
    return dog;
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breed',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 238, 178, 218)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dog Selector by Robert'),
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
  late Future<List<String>> futureDogBreeds;
  Dog? selectedDog;
  final MyAppState appState = MyAppState();
  int _selectedIndex = 0; // Index to keep track of selected page in the navbar

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void fetchDogData(String breed) async {
    final dog = await fetchDog(breed);
    setState(() {
      selectedDog = dog;
      appState.getNext();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Handler for "Adopt" button
  void adoptDog() {
    // You can display a dialog or perform any other action here.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Adopt Dog'),
          content: const Text('Thank you for adopting a dog! 🐶'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Handler for "Show me another one" button
  void showAnotherDog() {
    appState.getNext();  // Get a new random name (you can adjust it if needed)
    fetchDogData('bulldog'); // You can hard-code or pick any breed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          // Page 1: Dog Selector page
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder(
                  future: futureDogBreeds,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select a Breed',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.deepPurple.shade50,
                          ),
                          value: null,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                          style: const TextStyle(color: Colors.deepPurple, fontSize: 16),
                          items: snapshot.requireData
                              .map((breed) => DropdownMenuItem(
                                    value: breed,
                                    child: Text(breed.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ))
                              .toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              fetchDogData(newValue);
                            }
                          },
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    }
                    return const CircularProgressIndicator();
                  },
                ),
                const SizedBox(height: 20),
                if (selectedDog != null) ...[
                  Image.network(selectedDog!.imageUrl, height: 400, width: 400, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  Text(
                    'Dog Name: ${selectedDog!.name}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // Adopt button
                  ElevatedButton(
                    onPressed: adoptDog,
                    child: const Text('Adopt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Show me another button
                  ElevatedButton(
                    onPressed: showAnotherDog,
                    child: const Text('Show me another one'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Page 2: Add other page here if you want
          Center(child: Text("Other page content goes here!")),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
