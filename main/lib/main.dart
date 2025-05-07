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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 18, 28, 83),
        ),
        useMaterial3: true,
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
  late Future<List<Dog>> futureDogs;
  Future<Dog>? futureSelectedDog;
  bool hasSelection = false;

  @override
  void initState() {
    super.initState();
    futureDogs = fetchDogs();
  }

  void handleDogSelection(Dog dog) {
    setState(() {
      hasSelection = true;
      futureSelectedDog = fetchRandomDogImage(dog.breed);
    });
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Select a Dog",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder<List<Dog>>(
              future: futureDogs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  var dogs = snapshot.data!;
                  return DropdownMenu(
                    dropdownMenuEntries:
                        dogs
                            .map(
                              (dog) => DropdownMenuEntry(
                                value: dog,
                                label: dog.breed.toUpperCase(),
                              ),
                            )
                            .toList(),
                    onSelected: (value) {
                      if (value != null) handleDogSelection(value);
                    },
                  );
                }
                return const Text("No dogs found.");
              },
            ),
            if (hasSelection && futureSelectedDog != null)
              FutureBuilder<Dog>(
                future: futureSelectedDog,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            snapshot.data!.imageUrl,
                            height: 300,
                          ),
                        ),
                        Text(
                          snapshot.data!.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
          ],
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
      breed: breed,
      name: WordPair.random().join(""),
      imageUrl: imageUrl,
    );
  }
}

Future<List<Dog>> fetchDogs() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Dog> dogs = [];
    for (var breed in data['message'].keys) {
      final image = await fetchRandomDogImageUrl(breed);
      dogs.add(Dog.withRandomName(breed, image));
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
