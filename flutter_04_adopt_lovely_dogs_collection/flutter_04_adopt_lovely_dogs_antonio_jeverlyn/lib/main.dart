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
    return Dog(
      name: name.asPascalCase,
      imageUrl: json['message'],
      breed: breed,
    );
  }

  @override
  String toString() {
    return 'Dog Name: $name, Breed: $breed, Image URL: $imageUrl';
  }
}

Future<List<String>> fetchDogBreeds() async {
  final response = await http.get(
    Uri.parse('https://dog.ceo/api/breeds/list/all'),
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data['message'].keys);
  } else {
    throw Exception('Failed to load dog breeds');
  }
}

Future<Dog> fetchDog(String breed) async {
  final response = await http.get(
    Uri.parse('https://dog.ceo/api/breed/$breed/images/random'),
  );
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
          NavigationDestination(icon: Icon(Icons.pets), label: 'Adopted Dogs'),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard),
            label: 'Give Away',
          ),
          NavigationDestination(icon: Icon(Icons.info), label: 'About'),
        ],
        // Add this to change the color when selected
        backgroundColor:
            Colors.white, // Set the background color of the NavigationBar
        surfaceTintColor: Colors.transparent, //remove shadow
        shadowColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 80,
      ),
      body:
          <Widget>[
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Introduction Text
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Giving Paws a Second Chance, One Promise at a Time. Where Every Wag Gets a Forever Home.',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Dropdown for selecting a breed
                      FutureBuilder<List<String>>(
                        future: futureDogBreeds,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          return DropdownButton<String>(
                            hint: const Text('Select a breed'),
                            value: currentBreed,
                            items:
                                snapshot.data!
                                    .map(
                                      (breed) => DropdownMenuItem(
                                        value: breed,
                                        child: Text(breed.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  currentBreed = newValue;
                                  selectedDog = null; // Reset current dog
                                });
                                fetchDogData(newValue);
                              }
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Dog Image and Info
                      if (_isLoadingDog)
                        const CircularProgressIndicator()
                      else if (selectedDog != null) ...[
                        Image.network(
                          selectedDog!.imageUrl,
                          height: 250,
                          width: 250,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Dog Name: ${selectedDog!.name}\nBreed: ${selectedDog!.breed}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),

                        // Action Buttons
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
            ),

            GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Ensures 5 dogs per row
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                childAspectRatio: 0.9, // Adjust to fit image & text properly
              ),
              itemCount: adoptedDogs.length,
              itemBuilder: (context, index) {
                final dog = adoptedDogs[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  shadowColor: Colors.black26,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3, // Image takes more space
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Image.network(
                            dog.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2, // Text and button take remaining space
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                dog.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                dog.breed,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 5),
                              ElevatedButton(
                                onPressed: () => giveAwayDog(dog),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Give Away',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                      Image.network(
                        dog.imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        dog.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(dog.breed, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                );
              },
            ),
const Center(
  child: Padding(
    padding: EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Paws Promise is dedicated to rescuing, rehabilitating, and rehoming dogs in need.',
          style: TextStyle(
            fontFamily: 'Tahoma',
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          'We strive to create lasting bonds between loving families and deserving canine companions, fostering a community where every dog has the opportunity for a happy, healthy life.',
          style: TextStyle(
            fontFamily: 'Tahoma',
            fontSize: 18,
            color: Colors.black,
          ),
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 12),
        Text(
          'At Paws Promise, we believe every dog deserves a loving home. We are more than just an adoption agency—we are a bridge between compassionate families and wonderful dogs seeking their forever homes.',
          style: TextStyle(
            fontFamily: 'Tahoma',
            fontSize: 18,
            color: Colors.black,
          ),
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 12),
        Text(
          'Our journey begins with rescuing dogs from various situations, including shelters, abandonment, and hardship. Through proper care, love, and adoption, we give them a second chance at a joyful life.',
          style: TextStyle(
            fontFamily: 'Tahoma',
            fontSize: 18,
            color: Colors.black,
          ),
          textAlign: TextAlign.justify,
        ),
      ],
    ),
  ),
)

          ][currentPageIndex],
    );
  }
}