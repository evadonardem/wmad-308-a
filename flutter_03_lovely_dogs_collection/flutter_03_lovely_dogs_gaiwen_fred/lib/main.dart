import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math'; // For generating random dog names

void main() {
  runApp(const MyApp());
}

// DogBreed Class
class DogBreed {
  final String name;

  const DogBreed({required this.name});

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(
      name: json['name'] as String,
    );
  }
}

// Album Class
class Album {
  final int userId;
  final int id;
  final String title;

  const Album({required this.userId, required this.id, required this.title});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
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
    throw Exception('Failed to load dog image');
  }
}

Future<List<Album>> fetchAlbums() async {
  var albumsEndpoint = "https://jsonplaceholder.typicode.com/albums";
  final response = await http.get(Uri.parse(albumsEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body) as List;
    return data.map((json) => Album.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load albums');
  }
}

// List of random dog names
List<String> dogNames = [
  'Buddy', 'Charlie', 'Max', 'Bella', 'Lucy', 'Daisy', 'Rocky', 'Molly', 'Jake', 'Sadie',
  'Cooper', 'Toby', 'Bailey', 'Riley', 'Oliver', 'Chester', 'Zoe', 'Luna', 'Buster', 'Jack'
];

String getRandomDogName() {
  final random = Random();
  return dogNames[random.nextInt(dogNames.length)];
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
  late Future<List<Album>> futureAlbums;
  DogBreed? selectedBreed;
  Album? selectedAlbum;
  String? dogImageUrl;
  String? randomDogName;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
    futureAlbums = fetchAlbums();
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
                        dogImageUrl = null; // Reset the image when a new breed is selected
                        randomDogName = getRandomDogName(); // Get a random dog name
                      });
                      if (newValue != null) {
                        fetchDogImage(newValue.name).then((imageUrl) {
                          setState(() {
                            dogImageUrl = imageUrl;
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
            if (randomDogName != null)
              Text(
                'Random Dog Name: $randomDogName',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            if (dogImageUrl != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(dogImageUrl!),
              ),

            // Dropdown for Albums
            FutureBuilder<List<Album>>(
              future: futureAlbums,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return DropdownButton<Album>(
                    value: selectedAlbum,
                    items: snapshot.data!.map((Album album) {
                      return DropdownMenuItem<Album>(
                        value: album,
                        child: Text(album.title),
                      );
                    }).toList(),
                    onChanged: (Album? newAlbum) {
                      setState(() {
                        selectedAlbum = newAlbum;
                      });
                    },
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
            if (selectedAlbum != null)
              Text(
                'Selected Album: ${selectedAlbum!.title}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
          ],
        ),
      ),
    );
  }
}
