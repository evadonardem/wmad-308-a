import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

Future<String> fetchDogImage(String breed) async {
  var dogImageEndpoint = "https://dog.ceo/api/breed/$breed/images/random";
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['message'] as String;
  } else {
    throw Exception('FAILED to load dog image');
  }
}

class Album {
  final int userId;
  final int id;
  final String title;

  const Album({required this.userId, required this.id, required this.title});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 0, 0)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dog Breeds Selector'),
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
  String? breedImage;

  // List of words for the random dog name generator
  final List<String> firstWords = [
    'Fluffy', 'Bark', 'Mighty', 'Fierce', 'Happy', 'Gentle', 'Noble', 'Swift', 'Sleepy', 'Bold'
  ];
  
  final List<String> secondWords = [
    'Paws', 'Tail', 'Fur', 'Barker', 'Chaser', 'Runner', 'Puppy', 'Hunter', 'Sniffer', 'Barker'
  ];

  // Function to generate random dog name
  String generateRandomDogName() {
    final random = Random();
    String firstWord = firstWords[random.nextInt(firstWords.length)];
    String secondWord = secondWords[random.nextInt(secondWords.length)];
    return '$firstWord $secondWord';
  }

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
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
                if (snapshot.hasData) {
                  return DropdownButton<DogBreed>(
                    value: selectedBreed,
                    items: snapshot.data!.map((DogBreed breed) {
                      return DropdownMenuItem<DogBreed>(
                        value: breed,
                        child: Text(breed.name),
                      );
                    }).toList(),
                    onChanged: (DogBreed? newValue) {
                      setState(() {
                        selectedBreed = newValue;
                        breedImage = null; // Reset the image when a new breed is selected
                      });
                      if (newValue != null) {
                        fetchDogImage(newValue.name).then((imageUrl) {
                          setState(() {
                            breedImage = imageUrl;
                          });
                        }).catchError((error) {
                          setState(() {
                            breedImage = null;
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
                'Selected Breed: ${selectedBreed!.name}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            if (breedImage != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: 300,  // Increased width
                  height: 300, // Increased height
                  child: Image.network(
                    breedImage!,
                    fit: BoxFit.cover,  // Ensures the image fits within the container without distortion
                  ),
                ),
              ),
            if (breedImage == null && selectedBreed != null)
              const CircularProgressIndicator(), // Show a loading indicator if the image is not loaded yet

            // Display a random dog name
            Text(
              'Random Dog Name: ${generateRandomDogName()}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}
