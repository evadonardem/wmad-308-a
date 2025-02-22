import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds App',
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
  String _randomName = WordPair.random().asPascalCase;
  List<String> _breeds = [];
  bool _isLoading = false;
  bool _isImageLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  Future<void> _loadBreeds() async {
    setState(() => _isLoading = true);

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

  Future<void> _fetchBreedImage(String breed) async {
    setState(() => _isImageLoading = true);

    final response = await http.get(Uri.parse("https://dog.ceo/api/breed/$breed/images/random"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _dogImage = data['message'];
        _randomName = WordPair.random().asPascalCase;
        _isImageLoading = false;
      });
    } else {
      throw Exception('Failed to load dog image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dog Breeds & Names')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Dropdown with limited width
                      SizedBox(
                        width: 250, // Adjust width as needed
                        child: DropdownButtonFormField<String>(
                          value: _selectedBreed,
                          decoration: InputDecoration(
                            labelText: 'Select a Dog Breed',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.deepPurple.shade50,
                          ),
                          onChanged: (String? breed) {
                            setState(() => _selectedBreed = breed);
                            if (breed != null) _fetchBreedImage(breed);
                          },
                          items: _breeds.map((breed) {
                            return DropdownMenuItem<String>(
                              value: breed,
                              child: Text(
                                breed.toUpperCase(),
                                overflow: TextOverflow.ellipsis, // Prevents text overflow
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Show selected breed
                      if (_selectedBreed != null)
                        Text(
                          'You selected: $_selectedBreed',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),

                      const SizedBox(height: 20),

                      // Show loading indicator while fetching image
                      if (_isImageLoading)
                        const CircularProgressIndicator()
                      else if (_dogImage != null)
                        Column(
                          children: [
                            // Image with rounded corners inside a Card
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  _dogImage!,
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Dog name with decoration
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Meet your new dog: $_randomName',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
