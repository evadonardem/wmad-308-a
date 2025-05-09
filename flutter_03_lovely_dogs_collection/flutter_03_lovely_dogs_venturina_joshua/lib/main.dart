import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 58, 154, 183),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(58, 169, 183, 1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          textStyle: TextStyle(fontSize: 16, color: Colors.black),
        ),
        useMaterial3: true,
      ),
      home: const DogBreedsPage(),
    );
  }
}

class DogBreedsPage extends StatefulWidget {
  const DogBreedsPage({super.key});

  @override
  State<DogBreedsPage> createState() => _DogBreedsPageState();
}

class _DogBreedsPageState extends State<DogBreedsPage> {
  List<String> _breeds = [];
  String? _selectedBreed;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchDogBreeds();
  }

  Future<void> _fetchDogBreeds() async {
    final response = await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _breeds = List<String>.from(data['message'].keys);
      });
    }
  }

  Future<void> _fetchDogImage(String breed) async {
    final response = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _imageUrl = data['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter_03'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                hint: const Text('Select a breed'),
                value: _selectedBreed,
                items: _breeds.map((breed) {
                  return DropdownMenuItem(
                    value: breed,
                    child: Text(breed),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBreed = value;
                    _imageUrl = null;
                  });
                  _fetchDogImage(value!);
                },
              ),
              const SizedBox(height: 20),
              _imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(_imageUrl!, height: 250, fit: BoxFit.cover),
                    )
                  : const Text(
                      'Select a breed to see an image',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_selectedBreed != null) {
                    _fetchDogImage(_selectedBreed!);
                  }
                },
                child: const Text('Refresh Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
