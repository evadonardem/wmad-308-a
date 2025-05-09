import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class Dog {
  final String name;
  final String imageUrl;

  Dog({required this.name, required this.imageUrl});

  factory Dog.fromJson(WordPair name, Map<String, dynamic> json) {
    return Dog(name: name.asPascalCase, imageUrl: json['message']);
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
    WordPair dogName = WordPair.random();
    Dog dog = Dog.fromJson(dogName, data);
    print(dog);
    return dog;
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breed',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple), // Change to violet
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Lovely Dogs by Ganado, Linson'),
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
  final MyAppState appState = MyAppState();

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void fetchDogData(String breed) async {
    final dog = await fetchDog(breed);
    setState(() {
      selectedDog = dog;
      appState.getNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary, // Will now be a violet shade
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder(
                future: futureDogBreeds,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select a Breed',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.purple.shade50, // Change to a lighter violet
                        ),
                        value: null,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.purple), // Change to violet icon
                        style: const TextStyle(color: Colors.purple, fontSize: 16), // Change to violet text color
                        items: snapshot.requireData
                            .map((breed) => DropdownMenuItem(
                                  value: breed,
                                  child: Text(breed.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            fetchDogData(newValue);
                          }
                        },
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
            const SizedBox(height: 20),
            if (selectedDog != null) ...[
              Image.network(selectedDog!.imageUrl, height: 400, width: 400, fit: BoxFit.cover),
              const SizedBox(height: 10),
              Text(
                'Dog Name: ${selectedDog!.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
