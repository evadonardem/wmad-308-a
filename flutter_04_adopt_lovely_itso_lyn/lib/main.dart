import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  List<Map<String, String>> adoptedDogs = [];
  List<Map<String, String>> giveawayDogs = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(
            onAdopt: (dog) {
              setState(() {
                adoptedDogs.add(dog);
              });
            },
          ),
          AdoptedScreen(
            adoptedDogs: adoptedDogs,
            onGiveaway: (dog) {
              setState(() {
                adoptedDogs.remove(dog);
                giveawayDogs.add(dog);
              });
            },
          ),
          GiveawayScreen(giveawayDogs: giveawayDogs),
          const AboutScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.blue),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets, color: Colors.green),
            label: 'Adopted',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard, color: Colors.orange),
            label: 'Giveaway',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info, color: Colors.purple),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(Map<String, String>) onAdopt;
  const HomeScreen({super.key, required this.onAdopt});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? dogImageUrl;
  DogBreed? selectedBreed;
  List<DogBreed> breeds = [];
  final List<String> dogNames = ['Golden Retriever', 'Buddy', 'Charlie', 'Max', 'Milo', 'Rocky', 'Cooper', 'Duke', 'Bear', 'Toby', 'Leo'];
  final Random random = Random();
  String? displayedName;

  @override
  void initState() {
    super.initState();
    fetchDogBreeds().then((breedList) {
      setState(() {
        breeds = breedList;
      });
    });
  }

  Future<void> fetchRandomDog() async {
    if (selectedBreed == null) return;
    final response = await http.get(Uri.parse('https://dog.ceo/api/breed/${selectedBreed!.breed}/images/random'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        dogImageUrl = data['message'];
        displayedName = dogNames[random.nextInt(dogNames.length)];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlue[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Dog Haven!',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            if (breeds.isNotEmpty)
              DropdownButton<DogBreed>(
                hint: const Text('Select a breed'),
                value: selectedBreed,
                items: breeds.map((breed) {
                  return DropdownMenuItem<DogBreed>(
                    value: breed,
                    child: Text(breed.breed.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedBreed = value;
                    fetchRandomDog();
                  });
                },
              ),
            if (dogImageUrl != null)
              Column(
                children: [
                  Image.network(dogImageUrl!, width: 300, height: 300, fit: BoxFit.cover),
                  Text(
                    displayedName ?? 'Unknown',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: fetchRandomDog,
                  child: const Text('Show Another'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (selectedBreed != null && dogImageUrl != null) {
                      widget.onAdopt({'breed': '$displayedName (${selectedBreed!.breed})', 'image': dogImageUrl!});
                    }
                  },
                  child: const Text('Adopt'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdoptedScreen extends StatelessWidget {
  final List<Map<String, String>> adoptedDogs;
  final Function(Map<String, String>) onGiveaway;

  const AdoptedScreen({super.key, required this.adoptedDogs, required this.onGiveaway});

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, String>>> groupedDogs = {};

    // Group dogs by breed
    for (var dog in adoptedDogs) {
      String breed = dog['breed']!.split('(').last.split(')')[0]; // Extract breed name
      if (!groupedDogs.containsKey(breed)) {
        groupedDogs[breed] = [];
      }
      groupedDogs[breed]!.add(dog);
    }

    return Container(
      color: Colors.green[50],
      child: ListView(
        children: groupedDogs.keys.map((breed) {
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breed.toUpperCase(),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: groupedDogs[breed]!.map((dog) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(dog['image']!, width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dog['breed']!.split(' ')[0], // Extract dog name
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton(
  onPressed: () => onGiveaway(dog),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white, // Ensures text is readable
  ),
  child: const Text('Giveaway'),
),

                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class GiveawayScreen extends StatelessWidget {
  final List<Map<String, String>> giveawayDogs;
  const GiveawayScreen({super.key, required this.giveawayDogs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange[50],
      child: ListView.builder(
        itemCount: giveawayDogs.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Image.network(giveawayDogs[index]['image']!),
              title: Text(giveawayDogs[index]['breed']!),
            ),
          );
        },
      ),
    );
  }
}

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final List<String> feedbackList = [];

  void _submitFeedback() {
    if (_feedbackController.text.isNotEmpty) {
      setState(() {
        feedbackList.add(_feedbackController.text);
        _feedbackController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '🐶 About Dog Haven 🐶\n\n'
              'Dog Haven is your go-to app for discovering and adopting adorable dog breeds! '
              'Browse a variety of breeds, find a furry friend, and give them a loving home. '
              'With easy adoption and giveaway features, you can manage your pet collection effortlessly.\n',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Mission & Vision
            const Text(
              '🌟 Our Mission 🌟\n'
              'To connect loving families with wonderful dogs in need of a home. '
              'We believe every dog deserves a second chance, and we make the adoption process easy and enjoyable.\n',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              '🎯 Our Vision 🎯\n'
              'A world where every dog has a home and is treated with love and care.\n',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            // Contact Information
            const Text(
              '📞 Need Help? Contact Us! 📞\n'
              '📧 Email: support@doghaven.com\n'
              '📍 Location: 123 Dog Haven Street, Pet City\n'
              '📱 Call Us: +123-456-7890\n',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            // Feedback Section
            const Text(
              '📝 User Feedback 📝',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Enter your feedback...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _submitFeedback,
              child: const Text('Submit Feedback'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: feedbackList.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.feedback, color: Colors.purple),
                      title: Text(feedbackList[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class DogBreed {
  final String breed;
  const DogBreed({required this.breed});
  factory DogBreed.fromJson(String breed) {
    return DogBreed(breed: breed);
  }
}

Future<List<DogBreed>> fetchDogBreeds() async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['message'] as Map<String, dynamic>).keys.map((breed) => DogBreed(breed: breed)).toList();
  } else {
    throw Exception('Failed to load list of dog breeds');
  }
}