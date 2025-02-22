import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// DogBreed model class to parse JSON data
class DogBreed {
  final String breed;

  const DogBreed({required this.breed});

  factory DogBreed.fromJson(String breed) {
    return DogBreed(breed: breed);
  }
}

// Fetch all dog breeds
Future<List<DogBreed>> fetchDogBreeds() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final breeds = data['message'] as Map<String, dynamic>;

    // Convert the breed keys into DogBreed objects
    return breeds.keys.map((breed) {
      return DogBreed(breed: breed);
    }).toList();
  } else {
    throw Exception('Failed to load list of dog breeds');
  }
}

// Fetch image for the selected breed
Future<String> fetchBreedImage(String breed) async {
  final dogImageEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message']; // Returns the image URL for the selected breed
  } else {
    throw Exception('Failed to load image for $breed');
  }
}

// Main application widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo'),
    );
  }
}

// Home page widget with breed selection and image display
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<DogBreed>> futureDogBreeds;
  DogBreed? selectedBreed;
  String? breedImageUrl;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  // Handle breed selection and fetch corresponding image
  void _onBreedSelected(DogBreed breed) async {
    setState(() {
      selectedBreed = breed;
    });

    // Fetch the image for the selected breed
    String imageUrl = await fetchBreedImage(breed.breed);
    setState(() {
      breedImageUrl = imageUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder<List<DogBreed>>(
          future: futureDogBreeds,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              List<DogBreed> dogBreeds = snapshot.data!;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Dropdown to select a breed
                  DropdownButton<DogBreed>(
                    hint: const Text(''),
                    value: selectedBreed,
                    items: dogBreeds.map((breed) {
                      return DropdownMenuItem<DogBreed>(
                        value: breed,
                        child: Text(breed.breed.toUpperCase()), // Display breed in uppercase
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _onBreedSelected(value);  // Fetch and display the breed's image
                      }
                    },
                  ),
                  // Display the image of the selected breed
                  if (breedImageUrl != null)
                    Column(
                      children: [
                        Image.network(
                          breedImageUrl!,
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '${selectedBreed?.breed}',  // Display the breed name
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
