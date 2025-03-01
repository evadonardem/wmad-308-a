import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class DogName {
  final int id;
  final String name;

  const DogName({required this.id, required this.name});

  factory DogName.fromJson(Map<String, dynamic> json) {
    return DogName(
      id: json['id'],
      name: json['name'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds App with Names',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  String? _selectedBreed;
  String? _dogImage;
  String _randomName = WordPair.random().asCamelCase; // Random name from WordPair
  List<String> _breeds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  // Function to load dog breeds from the API
  Future<void> _loadBreeds() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(Uri.parse("https://dog.ceo/api/breeds/list/all"));

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

  // Function to fetch a dog image based on breed
  Future<void> _fetchBreedImage(String breed) async {
    final response = await http.get(Uri.parse("https://dog.ceo/api/breed/$breed/images/random"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _dogImage = data['message'];
        _randomName = WordPair.random().asCamelCase; // Generate a new random name on breed change
      });
    } else {
      throw Exception('Failed to load dog image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog Breeds with Random Names'),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Dropdown to select breed
                  DropdownButton<String>(
                    value: _selectedBreed,
                    hint: const Text('Select a Dog Breed'),
                    onChanged: (String? breed) {
                      setState(() {
                        _selectedBreed = breed;
                      });
                      if (breed != null) {
                        _fetchBreedImage(breed); // Fetch the image for the selected breed
                      }
                    },
                    items: _breeds.map((breed) {
                      return DropdownMenuItem<String>(
                        value: breed,
                        child: Text(breed.toUpperCase()),
                      );
                    }).toList(),
                  ),
                  if (_selectedBreed != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'You selected: $_selectedBreed',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_dogImage != null) ...[
                      const SizedBox(height: 20),
                      // Display the dog image
                      Image.network(
                        _dogImage!,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 20),
                      // Display the random name from WordPair
                      Text(
                        'Meet your new dog: $_randomName',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}