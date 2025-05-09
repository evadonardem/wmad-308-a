import 'dart:convert';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Album {
  final String title;  // We only need title (breed name)

  // Constructor for the Album class
  Album({required this.title});

  // Factory constructor to create Album from JSON data (if you ever need it)
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      title: json['name'],  // For example, 'name' as the breed name
    );
  }
}

Future<List<String>> fetchDogBreeds() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    Map<String, dynamic> breeds = data['message'];
    return breeds.keys.toList(); // Return the list of breed names
  } else {
    throw Exception('Failed to load dog breeds');
  }
}

Future<String> fetchDogImage(String breed) async {
  final dogImageEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message']; // Return the image URL
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  String? _selectedBreed;
  String? _dogImageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog Breed Selector'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<List<String>>(
              future: fetchDogBreeds(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No breeds found');
                } else {
                  List<String> breeds = snapshot.data!;
                  return DropdownButton<String>(
                    hint: const Text('Select a breed'),
                    value: _selectedBreed,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBreed = newValue;
                      });
                      // Fetch the image of the selected breed
                      if (newValue != null) {
                        fetchDogImage(newValue).then((imageUrl) {
                          setState(() {
                            _dogImageUrl = imageUrl;
                          });
                        }).catchError((e) {
                          // Handle error (optional)
                          setState(() {
                            _dogImageUrl = null;
                          });
                        });
                      }
                    },
                    items: breeds.map<DropdownMenuItem<String>>((String breed) {
                      return DropdownMenuItem<String>(
                        value: breed,
                        child: Text(breed),
                      );
                    }).toList(),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            // Display the dog image if available
            _dogImageUrl != null
                ? Image.network(
                    _dogImageUrl!,
                    width: 300, // Adjust the width if necessary
                    height: 300, // Adjust the height if necessary
                    fit: BoxFit.cover,
                  )
                : const Text('Select a breed to see the image'),
          ],
        ),
      ),
    );
  }
}