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
  final String breed;

  Dog({required this.name, required this.imageUrl, required this.breed});

  factory Dog.fromJson(WordPair name, String breed, Map<String, dynamic> json) {
    return Dog(name: name.asPascalCase, imageUrl: json['message'], breed: breed);
  }

  @override
  String toString() {
    return 'Dog Name: $name, Breed: $breed, Image URL: $imageUrl';
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
    Dog dog = Dog.fromJson(dogName, breed, data);
    return dog;
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Adoption App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  Dog? selectedDog;
  List<Dog> adoptedDogs = [];
  List<Dog> giveAwayDogs = [];
  late Future<List<String>> futureDogBreeds;
  String? currentBreed;
  bool _isLoadingDog = false;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void fetchDogData(String breed) async {
       setState(() {
      _isLoadingDog = true;
    });
    try {
      final dog = await fetchDog(breed);
        setState(() {
        selectedDog = dog;
        currentBreed = breed;
        _isLoadingDog = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDog = false;
      });
      print("Error fetching dog: $e");
      // Optionally, show an error message to the user
    }
  }

  void adoptDog() {
    if (selectedDog != null) {
      setState(() {
        adoptedDogs.add(selectedDog!);
        selectedDog = null;
      });
    }
  }

  void giveAwayDog(Dog dog) {
    setState(() {
      adoptedDogs.remove(dog);
      giveAwayDogs.add(dog);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.transparent, // Make indicator transparent
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets),
            label: 'Adopted Dogs',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard),
            label: 'Give Away',
          ),
          NavigationDestination(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
        // Add this to change the color when selected
        backgroundColor: Colors.white, // Set the background color of the NavigationBar
        surfaceTintColor: Colors.transparent, //remove shadow
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 80,
      ),
      body: <Widget>[
        SafeArea(
          child: Column(
            children: [
              // Fixed Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Every dog deserves a loving home, and you could be the one to give them that chance. Discover the joy of adoption—where a wagging tail and endless love are just a step away!',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  String? selectedBreed;

                  return FutureBuilder(
                    future: futureDogBreeds,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return DropdownButton<String>(
                          hint: const Text('Select a breed'),
                          value: selectedBreed,
                          items: snapshot.requireData
                              .map((breed) => DropdownMenuItem(
                                    value: breed,
                                    child: Text(breed.toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedBreed = newValue;
                              });
                              fetchDogData(newValue);
                            }
                          },
                        );
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }
                      return const CircularProgressIndicator();
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                         if (_isLoadingDog)
                          const CircularProgressIndicator()
                        else if (selectedDog != null) ...[
                        Image.network(selectedDog!.imageUrl, height: 300, width: 300, fit: BoxFit.cover),
                        const SizedBox(height: 10),
                        Text(
                          'Dog Name: ${selectedDog!.name}\nBreed: ${selectedDog!.breed}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: adoptDog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                              ),
                              child: const Text(
                                'Adopt',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => fetchDogData(currentBreed!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                              ),
                              child: const Text(
                                'Show Next',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: adoptedDogs.length,
          itemBuilder: (context, index) {
            final dog = adoptedDogs[index];
            return Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(dog.imageUrl, width: 100, height: 100, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  Text(dog.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(dog.breed, style: const TextStyle(fontSize: 14)),
                  ElevatedButton(
                    onPressed: () => giveAwayDog(dog),
                    child: const Text('Give Away'),
                  ),
                ],
              ),
            );
          },
        ),
        GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.8,
          ),
          itemCount: giveAwayDogs.length,
          itemBuilder: (context, index) {
            final dog = giveAwayDogs[index];
            return Card(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(dog.imageUrl, width: 100, height: 100, fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  Text(dog.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(dog.breed, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          },
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'At FurEverHome, our mission is to create lasting bonds by connecting rescue dogs with loving families, offering guidance and support to ensure every pup finds their perfect forever home.',
              style: TextStyle(
                fontFamily: 'Tahoma',
                fontSize: 18,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ][currentPageIndex],
    );
  }
}