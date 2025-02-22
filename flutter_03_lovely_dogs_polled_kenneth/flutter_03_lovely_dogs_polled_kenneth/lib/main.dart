import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart' show WordPair;

void main() {
  runApp(const MyApp());
}

class DogBreed {
  final String name;

  const DogBreed({required this.name});

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(
      name: json['name'] as String,
    );
  }
}

class Album {
  final int userId;
  final int id;
  final String title;

  const Album({required this.userId, required this.id, required this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }
}

Future<List<DogBreed>> fetchDogBreeds() async {
  var dogBreedsEndpoint = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var breeds = (data['message'] as Map<String, dynamic>).keys.map(
      (key) => DogBreed(name: key.toUpperCase()),
    ).toList();
    return breeds;
  } else {
    throw Exception('FAILED to load dog breeds');
  }
}

Future<String> fetchDogImage(String breed) async {
  var dogImageEndpoint = "https://dog.ceo/api/breed/$breed/images/random";
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('FAILED to load dog image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 0, 0)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  late Future<List<DogBreed>> futureDogBreeds;
  DogBreed? selectedBreed;
  String? dogImageUrl;
  String? dogName;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void _onBreedSelected(DogBreed? breed) async {
    if (breed != null) {
      final imageUrl = await fetchDogImage(breed.name.toLowerCase());
      setState(() {
        selectedBreed = breed;
        dogImageUrl = imageUrl;
        dogName = WordPair.random().asPascalCase; // Ensure random name generation
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<List<DogBreed>>(
              future: futureDogBreeds,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  );
                } else if (snapshot.hasData) {
                  return Container(
                    width: 600,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: DropdownButton<DogBreed>(
                      dropdownColor: const Color.fromARGB(255, 0, 0, 0),
                      value: selectedBreed,
                      items: snapshot.data!.map((DogBreed breed) {
                        return DropdownMenuItem<DogBreed>(
                          value: breed,
                          child: Center(
                            child: Text(
                              breed.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _onBreedSelected,
                      isExpanded: true,
                    ),
                  );
                } else {
                  return const Text(
                    'No data available',
                    style: TextStyle(color: Colors.white),
                  );
                }
              },
            ),
            if (selectedBreed != null)
              Text(
                'Selected Breed: ${selectedBreed!.name}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            if (dogImageUrl != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Image.network(
                      dogImageUrl!,
                      width: 400,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    Text(
                      'Name: $dogName',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}