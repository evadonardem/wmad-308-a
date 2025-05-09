import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class DogBreed {
  final String name;
  const DogBreed({required this.name});

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(name: json['name'] as String);
  }
}

class Album {
  final int userId;
  final int id;
  final String title;

  const Album({required this.userId, required this.id, required this.title});
}

Future<List<DogBreed>> fetchDogBreeds() async {
  var dogBreedsEndpoint = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var breeds = (data['message'] as Map<String, dynamic>).keys.map(
      (key) => DogBreed(name: key),
    ).toList();
    return breeds;
  } else {
    throw Exception('FAILED to load dog breeds');
  }
}

Future<String> fetchBreedImage(String breed) async {
  var breedImageEndpoint = "https://dog.ceo/api/breed/$breed/images/random";
  final response = await http.get(Uri.parse(breedImageEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['message'] as String;
  } else {
    throw Exception('Failed to load breed image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo by Alvarez Nigela',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 12, 11, 14)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'LOVELY DOGS BY ALVAREZ NIGELA'),
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
  String? breedImageUrl;
  String? randomDogName;

  final List<String> randomNames = [
    'Bogart', 'Maxine', 'Bella', 'Lucie', 'Momo', 'Nancy', 'Rocky', 'Daisy', 'Mico', 'Zoey'
  ];

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  // Function to generate a random name
  String getRandomName() {
    final random = Random();
    return randomNames[random.nextInt(randomNames.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      backgroundColor: const Color.fromARGB(255, 242, 241, 245),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<List<DogBreed>>(
              future: futureDogBreeds,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return DropdownButton<DogBreed>(
                    value: selectedBreed,
                    hint: Text(''),
                    items: snapshot.data!.map((DogBreed breed) {
                      return DropdownMenuItem<DogBreed>(
                        value: breed,
                        child: Text(breed.name),
                      );
                    }).toList(),
                    onChanged: (DogBreed? newValue) {
                      setState(() {
                        selectedBreed = newValue;
                        breedImageUrl = null;
                        randomDogName = getRandomName(); // Generate a random name when breed is selected
                      });
                      if (newValue != null) {
                        fetchBreedImage(newValue.name).then((imageUrl) {
                          setState(() {
                            breedImageUrl = imageUrl;
                          });
                        }).catchError((error) {
                          setState(() {
                            breedImageUrl = null;
                          });
                        });
                      }
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
            if (selectedBreed != null)
              Text(
                '$randomDogName', // Show breed and random name
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            if (breedImageUrl != null)
              Column(
                children: [
                  Container(
                    width: 250,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.network(
                      breedImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            if (selectedBreed == null)
              const Text(
                ' ',
                style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 214, 217, 223)),
              ),
          ],
        ),
      ),
    );
  }
}