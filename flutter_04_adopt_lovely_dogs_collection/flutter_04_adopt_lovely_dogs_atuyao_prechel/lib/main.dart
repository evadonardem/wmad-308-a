import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

Future<List<String>> fetchDogBreeds() async {
  final response = await http.get(
    Uri.parse('https://dog.ceo/api/breeds/list/all'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List.from(data['message'].keys);
  } else {
    throw Exception('Failed to load breeds');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Adoption',
      theme: ThemeData(useMaterial3: true),
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
  final List<Map<String, String>> adoptedDogs = [];
  final List<Map<String, String>> giveawayDogs = [];

  void adoptDog(String breed, String name, String imageUrl) {
    setState(() {
      adoptedDogs.add({'breed': breed, 'name': name, 'image': imageUrl});
    });
  }

  void giveAwayDog(int index) {
    setState(() {
      giveawayDogs.add(adoptedDogs[index]);
      adoptedDogs.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.pets, size: 30, color: Colors.white),
            SizedBox(width: 10),
            Text(
              '"Be the Change: Adopt, Love, and Give Back"',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromARGB(
          255,
          217,
          224,
          230,
        ), // Custom color for the navigation bar
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.pets), label: 'Adopted Dogs'),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard),
            label: 'Give Away',
          ),
          NavigationDestination(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
      body:
          <Widget>[
            DogBreedSelector(onAdopt: adoptDog),
            AdoptedDogsPage(adoptedDogs: adoptedDogs, onGiveAway: giveAwayDog),
            GiveawayDogsPage(giveawayDogs: giveawayDogs),
            const AboutPage(),
          ][currentPageIndex],
    );
  }
}

class DogBreedSelector extends StatefulWidget {
  final Function(String, String, String) onAdopt;

  const DogBreedSelector({super.key, required this.onAdopt});

  @override
  State<DogBreedSelector> createState() => _DogBreedSelectorState();
}

class _DogBreedSelectorState extends State<DogBreedSelector> {
  late Future<List<String>> futureDogBreeds;
  String? selectedBreed;
  String? dogName;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  Future<void> fetchDogImage(String breed) async {
    final response = await http.get(
      Uri.parse('https://dog.ceo/api/breed/$breed/images/random'),
    );
    if (response.statusCode == 200) {
      setState(() {
        imageUrl = jsonDecode(response.body)['message'];
      });
    }
  }

  void selectBreed(String breed) {
    setState(() {
      selectedBreed = breed;
      dogName = WordPair.random().asPascalCase;
    });
    fetchDogImage(breed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        207,
        226,
        183,
      ), // Page-specific background color
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Dropdown Menu to select the dog breed
              FutureBuilder(
                future: futureDogBreeds,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final dropdownItems =
                        snapshot.data!
                            .map(
                              (name) => DropdownMenuEntry(
                                value: name,
                                label: name.toUpperCase(),
                              ),
                            )
                            .toList();

                    return DropdownMenu(
                      dropdownMenuEntries: dropdownItems,
                      onSelected: (value) {
                        if (value != null) selectBreed(value);
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
              const SizedBox(height: 20),
              if (selectedBreed != null && imageUrl != null) ...[
                Text(
                  'Name: $dogName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 250,
                  child: Image.network(imageUrl!, fit: BoxFit.cover),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => fetchDogImage(selectedBreed!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          32,
                          143,
                          218,
                        ), // Custom color for the "Show Another One" button
                      ),
                      child: const Text(
                        'Show Another One',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Make the text bold
                          color: Color.fromARGB(255, 10, 10, 10), // Text color
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed:
                          () => widget.onAdopt(
                            selectedBreed!,
                            dogName!,
                            imageUrl!,
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          31,
                          96,
                          194,
                        ), // Custom color for the "Adopt" button
                      ),
                      child: const Text(
                        'Adopt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, // Make the text bold
                          color: Color.fromARGB(255, 14, 13, 13), // Text color
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AdoptedDogsPage extends StatelessWidget {
  final List<Map<String, String>> adoptedDogs;
  final Function(int) onGiveAway;

  const AdoptedDogsPage({
    super.key,
    required this.adoptedDogs,
    required this.onGiveAway,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        183,
        209,
        152,
      ), // Background color for the page
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: const [
                Icon(Icons.pets, size: 40, color: Colors.brown),
                SizedBox(width: 10),
                Text(
                  'Adopted Dogs',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: adoptedDogs.length,
              itemBuilder: (context, index) {
                final dog = adoptedDogs[index];
                return ListTile(
                  leading: Image.network(dog['image']!, width: 50, height: 50),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${dog['name']}'),
                      Text('Breed: ${dog['breed']}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => onGiveAway(index),
                    child: const Text('Give Away'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GiveawayDogsPage extends StatelessWidget {
  final List<Map<String, String>> giveawayDogs;

  const GiveawayDogsPage({super.key, required this.giveawayDogs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        183,
        209,
        152,
      ), // Set the background color of the page
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: const [
                Icon(Icons.card_giftcard, size: 40, color: Colors.brown),
                SizedBox(width: 10),
                Text(
                  'Give Away Dogs',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: giveawayDogs.length,
              itemBuilder: (context, index) {
                final dog = giveawayDogs[index];
                return ListTile(
                  leading: Image.network(dog['image']!, width: 50, height: 50),
                  title: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align the text to the left
                    children: [
                      Text('Name: ${dog['name']}'),
                      Text('Breed: ${dog['breed']}'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final TextEditingController _reviewController = TextEditingController();

  void _submitReview() {
    final reviewMessage = _reviewController.text.trim();

    if (reviewMessage.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a review before submitting.'),
        ),
      );
    } else {
      print('Review submitted: $reviewMessage');
      _reviewController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your review!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        201,
        184,
        196,
      ), // Page-specific background color
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50.0),
                    child: Text(
                      'Welcome to the Dog Adoption app, your go-to platform for adopting and caring for your furry friends. '
                      'This app allows you to explore a variety of dog breeds, view their images, and easily adopt the one that melts your heart. '
                      'We aim to make the dog adoption process smooth and enjoyable by offering a fun way to interact with the available breeds, '
                      'name your new companion, and even give away dogs once they have been adopted. Whether you are looking for a playful pup or a loyal companion, '
                      'our app provides an intuitive interface to help you find the perfect dog. '
                      'We also value your feedback! Please leave a review and let us know how we can improve the app for future users. '
                      'Thank you for being a part of our community and helping to give these dogs a loving home.',
                      semanticsLabel:
                          'About page description for the Dog Adoption app.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'We value your feedback!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please leave a review and let us know how we can improve the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter your review...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitReview,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Submit Review'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Icon(Icons.pets, size: 50, color: Colors.brown),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                backgroundColor: Colors.blue,
              ),
              child: const Text('Sign In / Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}
