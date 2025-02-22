import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

// Dog Model with Album-style structure
class Dog {
  final String breed;
  final String name;

  const Dog({required this.breed, required this.name});

  factory Dog.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'breed': String breed} => Dog(
          breed: breed,
          name: WordPair.random().asPascalCase, // Generate random dog name
        ),
      _ => throw FormatException("Invalid JSON format"),
    };
  }
}

// Fetch list of breeds
Future<List<String>> fetchBreeds() async {
  var url = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var breeds = data['message'] as Map<String, dynamic>;
    return breeds.keys.toList(); // Convert breed names to a list
  } else {
    throw Exception('Failed to load dog breeds');
  }
}

// Fetch breed image
Future<String> fetchDogImage(String breed) async {
  var url = "https://dog.ceo/api/breed/$breed/images/random";
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['message']; // Image URL
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dog Breeds & Names'),
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
  String? _selectedBreed;
  late Future<List<String>> _breedsFuture;
  String? _dogImage;
  String? _dogName;

  @override
  void initState() {
    super.initState();
    _breedsFuture = fetchBreeds(); // Fetch breeds when initialized
  }

  void _fetchBreedDetails(String breed) async {
    setState(() {
      _dogImage = null; // Reset image while loading
      _dogName = null;  // Reset name while loading
    });

    try {
      String imageUrl = await fetchDogImage(breed);
      Dog dog = Dog.fromJson({'breed': breed}); // Generate a random dog name

      setState(() {
        _dogImage = imageUrl;
        _dogName = dog.name; // Update dog name
      });
    } catch (e) {
      setState(() {
        _dogImage = null;
        _dogName = null;
      });
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<List<String>>(
          future: _breedsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              List<String> dogBreeds = snapshot.data!;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Select a Dog Breed:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _selectedBreed,
                    hint: const Text('Choose a breed'),
                    onChanged: (String? newBreed) {
                      setState(() {
                        _selectedBreed = newBreed;
                      });
                      if (newBreed != null) {
                        _fetchBreedDetails(newBreed);
                      }
                    },
                    items: dogBreeds.map<DropdownMenuItem<String>>((String breed) {
                      return DropdownMenuItem<String>(
                        value: breed,
                        child: Text(breed.toUpperCase()), // Capitalized breed
                      );
                    }).toList(),
                  ),
                  if (_selectedBreed != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'You selected: ${_selectedBreed!.toUpperCase()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (_dogImage != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15), // Rounded corners for aesthetics
                            child: Image.network(
                              _dogImage!,
                              width: 300,
                              height: 300,
                              fit: BoxFit.cover, // Ensures image fits nicely
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _dogName ?? '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  if (_dogImage == null && _selectedBreed != null)
                    const CircularProgressIndicator(),
                ],
              );
            } else {
              return const Text('No data available');
            }
          },
        ),
      ),
    );
  }
}
