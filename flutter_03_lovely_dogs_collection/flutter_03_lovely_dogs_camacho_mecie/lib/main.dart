import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Dog {
  final String name;
  final String imageUrl;

  Dog({required this.name, required this.imageUrl});

  // Factory constructor to create Dog from JSON
  factory Dog.fromJson(String breed, Map<String, dynamic> json) {
    return Dog(name: breed, imageUrl: json['message']);
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
    return Dog.fromJson(breed, data);
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dog Breed Selector'),
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

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void fetchDogData(String breed) async {
    final dog = await fetchDog(breed);
    setState(() {
      selectedDog = dog;
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
            FutureBuilder<List<String>>(
              future: futureDogBreeds,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                } else if (snapshot.hasData) {
                  return DropdownButton<String>(
                    hint: const Text('Select a breed'),
                    items: snapshot.data!
                        .map((breed) => DropdownMenuItem(
                              value: breed,
                              child: Text(breed.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        fetchDogData(newValue);
                      }
                    },
                  );
                }
                return const Text('No breeds found');
              },
            ),
            const SizedBox(height: 20),
            if (selectedDog != null) ...[
              Image.network(selectedDog!.imageUrl, height: 400, width: 400, fit: BoxFit.cover),
              const SizedBox(height: 10),
              Text(
                'Dog Breed: ${selectedDog!.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
