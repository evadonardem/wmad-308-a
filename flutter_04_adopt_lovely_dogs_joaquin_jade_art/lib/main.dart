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
    var breeds = (data['message'] as Map<String, dynamic>)
        .keys
        .map(
          (key) => DogBreed(name: key.toUpperCase()),
        )
        .toList();
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

  GiveAwayDog(
      {required this.breed, required this.imageUrl, required this.name});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 0, 150, 136)), // Changed primary color
        useMaterial3: true,
        scaffoldBackgroundColor:
            Colors.teal[50], // Changed background color
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
              color: Colors.white), // Changed text color to white
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
      body: Center(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            MyHomePage(
                title: 'ADOPT A DOG', adoptedDogs: adoptedDogs),
            AdoptedDogsPage(
                adoptedDogs: adoptedDogs, giveAwayDogs: giveAwayDogs),
            GiveAwayPage(giveAwayDogs: giveAwayDogs),
            const AboutPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black), // Changed icon color to black
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
        selectedItemColor: Colors.white, // Changed selected item color to white
        unselectedItemColor: Colors.black, // Changed unselected item color to black
        backgroundColor: Colors.teal[800], // Changed background color to a darker teal
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Remove hover effect
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'About this App',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome to the Dog Adoption App! Here you can explore various dog breeds, view random dog images, and adopt or give away a dog.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Our mission is to help connect loving homes with adorable dogs. Whether you are looking to adopt a dog or give one away, this app aims to make the process simple and fun!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Built with Flutter and powered by Jade Art A. Joaquin, the app fetches a wide variety of dog breeds and random images to help you find your perfect pet companion.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Changed text color to black
                      ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<DogBreed>>(
                  future: futureDogBreeds,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.black),
                      );
                    } else if (snapshot.hasData) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: DropdownButton<DogBreed>(
                          dropdownColor: Colors.white,
                          value: selectedBreed,
                          items: snapshot.data!.map((DogBreed breed) {
                            return DropdownMenuItem<DogBreed>(
                              value: breed,
                              child: Center(
                                child: Text(
                                  breed.name,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _onBreedSelected,
                          isExpanded: true,
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    } else {
                      return const Text(
                        'No data available',
                        style: TextStyle(color: Colors.black),
                      );
                    }
                  },
                ),
                if (selectedBreed != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      'Selected Breed: ${selectedBreed!.name}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.black, // Changed text color to black
                          ),
                    ),
                  ),
                if (dogImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Image.network(
                            dogImageUrl!,
                            width: 350,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Name: $dogName',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.black, // Changed text color to black
                              ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _adoptDog,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(150, 50), backgroundColor: Colors.amber,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: const Text('Adopt Me'),
                            ),
                            ElevatedButton(
                              onPressed: _showAnotherDog,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(150, 50), backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                              child: const Text('Show Me Another Dog'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdoptedDogsPage extends StatelessWidget {
  const AdoptedDogsPage(
      {super.key, required this.adoptedDogs, required this.giveAwayDogs});

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
            leading: Image.network(dog.imageUrl,
                width: 50, height: 50, fit: BoxFit.cover),
            title: Text(dog.name, style: const TextStyle(color: Colors.black)),
            subtitle:
                Text(dog.breed, style: const TextStyle(color: Colors.black)),
            trailing: IconButton(
              icon: const Icon(Icons.local_offer,
                  color: Color.fromARGB(255, 0, 0, 0)),
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
                    builder: (context) =>
                        GiveAwayPage(giveAwayDogs: giveAwayDogs),
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
            leading: Image.network(dog.imageUrl,
                width: 50, height: 50, fit: BoxFit.cover),
            title: Text(dog.name, style: const TextStyle(color: Colors.black)),
            subtitle:
                Text(dog.breed, style: const TextStyle(color: Colors.black)),
          );
        },
      ),
    );
  }
}
