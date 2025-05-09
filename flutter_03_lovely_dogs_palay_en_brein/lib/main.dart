import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() => runApp(const MyApp());

class Dog {
  final String name, imageUrl;
  Dog({required this.name, required this.imageUrl});

  factory Dog.fromJson(WordPair name, Map<String, dynamic> json) =>
      Dog(name: name.asPascalCase, imageUrl: json['message']);
}

Future<List<String>> fetchDogBreeds() async {
  final response =
      await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data['message'].keys);
  } else {
    throw Exception('Failed to load breeds');
  }
}

Future<Dog> fetchDog(String breed) async {
  final response = await http
      .get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return Dog.fromJson(WordPair.random(), data);
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jerick Breeds',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 7, 233, 63)),
          useMaterial3: true),
      home: const MyHomePage(title: 'Select your Breed (DOGS)'),
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
    setState(() => selectedDog = dog);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder<List<String>>(
                future: futureDogBreeds,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return DropdownButton<String>(
                      hint: const Text('Select a breed'),
                      items: snapshot.data!
                          .map((breed) => DropdownMenuItem(
                              value: breed, child: Text(breed.toUpperCase())))
                          .toList(),
                      onChanged: (newValue) =>
                          newValue != null ? fetchDogData(newValue) : null,
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 20),
              if (selectedDog != null) ...[
                Image.network(selectedDog!.imageUrl,
                    height: 300, width: 300, fit: BoxFit.cover),
                const SizedBox(height: 10),
                Text(selectedDog!.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ]),
      ),
    );
  }
}
