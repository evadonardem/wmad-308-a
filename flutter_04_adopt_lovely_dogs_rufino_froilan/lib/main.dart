import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart'; // Import english_words package
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class Dog {
  final String name;
  final String imageUrl;
  final String strength;

  Dog({required this.name, required this.imageUrl, required this.strength});
}

Future<List<String>> fetchDogBreeds() async {
  var dogBreedsEndpoint = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var breeds = (data['message'] as Map<String, dynamic>).keys.toList();
    return breeds;
  } else {
    throw Exception('FAILED to load dog breeds');
  }
}

Future<String> fetchDogImage(String breed) async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('Failed to load dog image');
  }
}

// Define possible strengths for each dog breed
Map<String, List<String>> dogStrengths = {
  'bulldog': ['Strong protector', 'Loyal companion', 'Courageous'],
  'labrador': ['Friendly and sociable', 'Great for families', 'Energetic and playful'],
  'beagle': ['Great sense of smell', 'Loyal', 'Friendly'],
  'poodle': ['Intelligent', 'Easy to train', 'Elegant'],
  'terrier': ['Energetic', 'Feisty', 'Brave'],
};

String getRandomStrength(String breed) {
  final random = Random();
  List<String> strengths = dogStrengths[breed.toLowerCase()] ?? ['No strengths available'];
  return strengths[random.nextInt(strengths.length)];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Image App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 18, 3, 87)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Dog Image App'),
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
  String? selectedBreed;
  String? dogImageUrl;
  Dog? randomDog;
  int _selectedIndex = 0; // Index for bottom navigation bar
  List<Dog> adoptedDogs = []; // List to store adopted dogs

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void _showNext() {
    if (selectedBreed != null) {
      fetchDogImage(selectedBreed!).then((imageUrl) {
        setState(() {
          dogImageUrl = imageUrl;
          randomDog = Dog(
            name: WordPair.random().asPascalCase, // Random name
            imageUrl: imageUrl, // Fetch image
            strength: getRandomStrength(selectedBreed!), // Get random strength
          );
        });
      });
    }
  }

  void _adoptDog() {
    if (randomDog != null) {
      setState(() {
        adoptedDogs.add(randomDog!); // Add the current dog to the adopted list
      });
      // Navigate to the Adopted Dogs page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdoptedDogsPage(adoptedDogs: adoptedDogs),
        ),
      );
    }
  }

  // Bottom navigation bar item selection handler
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      // Navigate to the Adopted Dogs page when "Adopt" is selected
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdoptedDogsPage(adoptedDogs: adoptedDogs),
        ),
      );
    }
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
            // Display the selected breed text
            if (selectedBreed != null)
              Text(
                'Selected Breed: $selectedBreed',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            SizedBox(height: 20),
            // Dropdown is always visible
            FutureBuilder<List<String>>(
              future: futureDogBreeds,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Container(
                    width: 300, // Set a width for the dropdown
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 92, 2, 2).withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: selectedBreed,
                      isExpanded: true, // Make the dropdown full width
                      items: snapshot.data!.map((String breed) {
                        return DropdownMenuItem<String>(
                          value: breed,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              breed,
                              style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 203, 218, 6)),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBreed = newValue;
                          dogImageUrl = null; // Reset image
                          randomDog = null; // Reset the dog object
                        });
                        if (newValue != null) {
                          // Fetch new dog image for the selected breed
                          fetchDogImage(newValue).then((imageUrl) {
                            setState(() {
                              dogImageUrl = imageUrl;
                              // Generate random dog name using WordPair
                              randomDog = Dog(
                                name: WordPair.random().asPascalCase, // Random name
                                imageUrl: imageUrl, // Fetch image
                                strength: getRandomStrength(newValue), // Get random strength
                              );
                            });
                          });
                        }
                      },
                      style: TextStyle(color: const Color.fromARGB(255, 89, 207, 11)),
                      dropdownColor: const Color.fromARGB(255, 4, 201, 174),
                      underline: Container(), // Remove default underline
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                return const CircularProgressIndicator();
              },
            ),
            SizedBox(height: 20),
            // Display the dog's image, name, and strength if available
            if (randomDog != null)
              Column(
                children: [
                  Container(
                    width: 250, // Set width for the image container
                    height: 250, // Set height for the image container
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20), // Rounded corners for image
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 187, 7, 157).withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        randomDog!.imageUrl,
                        fit: BoxFit.cover, // Image should cover the box
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Dog Name: ${randomDog!.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Strength: ${randomDog!.strength}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            if (randomDog == null && selectedBreed != null)
              const CircularProgressIndicator(), // Show loading spinner if image is being fetched
            SizedBox(height: 20),
            // Row with the "Adopt" and "Show Next" buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _adoptDog,
                  child: const Text('Adopt'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _showNext,
                  child: const Text('Show Next'),
                ),
              ],
            ),
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Color for selected item
        unselectedItemColor: Colors.grey, // Color for unselected items
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: 'Adopt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload),
            label: 'Give Away',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

// Adopted Dogs Page
class AdoptedDogsPage extends StatelessWidget {
  final List<Dog> adoptedDogs;

  const AdoptedDogsPage({super.key, required this.adoptedDogs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adopted Dogs'),
      ),
      body: adoptedDogs.isEmpty
          ? const Center(
              child: Text(
                'No dogs adopted yet!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: adoptedDogs.length,
              itemBuilder: (context, index) {
                final dog = adoptedDogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dog Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            dog.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Dog Name and Strength
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dog.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Strength: ${dog.strength}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}