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

class AdoptedDog {
  final String breed;
  final String imageUrl;
  final String name;

  AdoptedDog({required this.breed, required this.imageUrl, required this.name});
}

class GiveAwayDog {
  final String breed;
  final String imageUrl;
  final String name;

  GiveAwayDog({required this.breed, required this.imageUrl, required this.name});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breed App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 0, 0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color.fromARGB(255, 9, 179, 198),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  List<AdoptedDog> adoptedDogs = [];
  List<GiveAwayDog> giveAwayDogs = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            MyHomePage(title: 'Flutter Demo Home Page', adoptedDogs: adoptedDogs),
            AdoptedDogsPage(adoptedDogs: adoptedDogs, giveAwayDogs: giveAwayDogs),
            GiveAwayPage(giveAwayDogs: giveAwayDogs),
            const AboutPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Adopted Dogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Give Away',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'About Page',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.adoptedDogs});

  final String title;
  final List<AdoptedDog> adoptedDogs;

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
      await _fetchNewDog(breed);
    }
  }

  Future<void> _fetchNewDog(DogBreed breed) async {
    final imageUrl = await fetchDogImage(breed.name.toLowerCase());
    setState(() {
      selectedBreed = breed;
      dogImageUrl = imageUrl;
      dogName = WordPair.random().asPascalCase; // Ensure random name generation
    });
  }

  void _showAnotherDog() async {
    if (selectedBreed != null) {
      final imageUrl = await fetchDogImage(selectedBreed!.name.toLowerCase());
      setState(() {
        dogImageUrl = imageUrl;
        dogName = WordPair.random().asPascalCase; // Change the dog name
      });
    }
  }

  void _adoptDog() {
    if (selectedBreed != null && dogImageUrl != null && dogName != null) {
      setState(() {
        widget.adoptedDogs.add(AdoptedDog(
          breed: selectedBreed!.name,
          imageUrl: dogImageUrl!,
          name: dogName!,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    ElevatedButton(
                      onPressed: _adoptDog,
                      child: const Text('Adopt Me'),
                    ),
                    ElevatedButton(
                      onPressed: _showAnotherDog,
                      child: const Text('Show Me Another Dog'),
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

class AdoptedDogsPage extends StatelessWidget {
  const AdoptedDogsPage({super.key, required this.adoptedDogs, required this.giveAwayDogs});

  final List<AdoptedDog> adoptedDogs;
  final List<GiveAwayDog> giveAwayDogs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopted Dogs'),
      ),
      body: ListView.builder(
        itemCount: adoptedDogs.length,
        itemBuilder: (context, index) {
          final dog = adoptedDogs[index];
          return ListTile(
            leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(dog.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(dog.breed, style: const TextStyle(color: Colors.white)),
            trailing: IconButton(
              icon: const Icon(Icons.local_offer, color: Colors.amber),
              onPressed: () {
                // Move to giveaway page
                giveAwayDogs.add(GiveAwayDog(
                  breed: dog.breed,
                  imageUrl: dog.imageUrl,
                  name: dog.name,
                ));
                adoptedDogs.removeAt(index);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GiveAwayPage(giveAwayDogs: giveAwayDogs),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class GiveAwayPage extends StatelessWidget {
  const GiveAwayPage({super.key, required this.giveAwayDogs});

  final List<GiveAwayDog> giveAwayDogs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Give Away Dogs'),
      ),
      body: ListView.builder(
        itemCount: giveAwayDogs.length,
        itemBuilder: (context, index) {
          final dog = giveAwayDogs[index];
          return ListTile(
            leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(dog.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(dog.breed, style: const TextStyle(color: Colors.white)),
          );
        },
      ),
    );
  }
}