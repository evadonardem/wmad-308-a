import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class Dog {
  final String name;
  final String gender;
  final DateTime birthDate;
  final String imageUrl;
  final String breed;

  Dog({
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.imageUrl,
    required this.breed,
  });
}

// List of common dog names for random generation
List<String> dogNames = [
  'Buddy', 'Max', 'Bella', 'Charlie', 'Luna', 'Lucy', 'Cooper', 'Daisy', 'Bailey', 'Rocky'
];

// List of genders for random assignment
List<String> dogGenders = ['Male', 'Female'];

// Function to generate a random dog name, gender, birthdate, and breed
Dog generateRandomDog(String imageUrl, String breed) {
  final random = Random();
  final name = dogNames[random.nextInt(dogNames.length)];
  final gender = dogGenders[random.nextInt(dogGenders.length)];
  final birthDate = DateTime(2015 + random.nextInt(5), random.nextInt(12) + 1, random.nextInt(28) + 1);

  return Dog(
    name: name,
    gender: gender,
    birthDate: birthDate,
    imageUrl: imageUrl,
    breed: breed,
  );
}

Future<List<String>> fetchDogBreeds() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    Map<String, dynamic> breeds = data['message'];
    return breeds.keys.toList();
  } else {
    throw Exception('Failed to load dog breeds');
  }
}

Future<String> fetchDogImage(String breed) async {
  final dogImageEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message']; // Return the image URL
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  List<Dog> _adoptedDogs = [];
  List<Dog> _giveAwayDogs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dog Breed Selector')),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePageContent(onAdopt: _adoptDog),
          AdoptedDogsPage(
            adoptedDogs: _adoptedDogs,
            onDogClicked: _handleDogClick,
            onGiveAway: _giveAwayDog,
          ),
          GiveAwayPage(giveAwayDogs: _giveAwayDogs),
          const AboutPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopted Dogs'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Give Away Dogs'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }

  void _adoptDog(Dog dog) {
    setState(() => _adoptedDogs.add(dog));
  }

  void _giveAwayDog(Dog dog) {
    setState(() {
      _adoptedDogs.remove(dog);
      _giveAwayDogs.add(dog);
    });
  }

  void _handleDogClick(Dog dog) {}
}

class HomePageContent extends StatefulWidget {
  final Function(Dog) onAdopt;

  const HomePageContent({super.key, required this.onAdopt});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  String? _selectedBreed;
  String? _dogImageUrl;
  String? _dogName;
  bool _isLoading = false;

  Future<void> _loadNewDog() async {
    if (_selectedBreed == null) return;
    setState(() => _isLoading = true);

    final imageUrl = await fetchDogImage(_selectedBreed!);
    final newDog = generateRandomDog(imageUrl, _selectedBreed!);

    setState(() {
      _dogImageUrl = newDog.imageUrl;
      _dogName = newDog.name;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FutureBuilder<List<String>>(
            future: fetchDogBreeds(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return DropdownButton<String>(
                  hint: const Text('Select a breed'),
                  value: _selectedBreed,
                  onChanged: (String? newValue) async {
                    setState(() => _selectedBreed = newValue);
                    await _loadNewDog();
                  },
                  items: snapshot.data!
                      .map((breed) => DropdownMenuItem(value: breed, child: Text(breed)))
                      .toList(),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          _dogImageUrl != null
              ? Column(
                  children: [
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      Image.network(_dogImageUrl!, width: 300, height: 300, fit: BoxFit.cover),
                      const SizedBox(height: 10),
                      Text(_dogName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ]
                  ],
                )
              : const Text('Select a breed to see the image'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (_dogImageUrl != null && _selectedBreed != null) {
                    widget.onAdopt(generateRandomDog(_dogImageUrl!, _selectedBreed!));
                  }
                },
                child: const Text('Adopt'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _loadNewDog,
                child: const Text('Show Next Dog'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class AdoptedDogsPage extends StatelessWidget {
  final List<Dog> adoptedDogs;
  final Function(Dog) onDogClicked;
  final Function(Dog) onGiveAway;

  const AdoptedDogsPage({
    super.key,
    required this.adoptedDogs,
    required this.onDogClicked,
    required this.onGiveAway,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adopted Dogs')),
      body: ListView.builder(
        itemCount: adoptedDogs.length,
        itemBuilder: (context, index) {
          final dog = adoptedDogs[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
              title: Text(dog.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dog.breed),
                  TextButton(
                    onPressed: () => onGiveAway(dog),
                    child: const Text('Give Away', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              onTap: () => onDogClicked(dog),
            ),
          );
        },
      ),
    );
  }
}


class GiveAwayPage extends StatelessWidget {
  final List<Dog> giveAwayDogs;

  const GiveAwayPage({super.key, required this.giveAwayDogs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Away Dogs')),
      body: ListView.builder(
        itemCount: giveAwayDogs.length,
        itemBuilder: (context, index) {
          final dog = giveAwayDogs[index];
          return ListTile(
            leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(dog.name),
            subtitle: Text(dog.breed),
          );
        },
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Me')),
      body: const Center(child: Text('Short information about the app creator.')),
      //jasmine
    );
  }
}
