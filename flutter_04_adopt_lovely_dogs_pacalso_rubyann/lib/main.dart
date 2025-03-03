import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class Dog {
  final String breed;
  final String name;
  final String imageUrl;

  Dog({required this.breed, required this.name, required this.imageUrl});
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<Dog> _adoptedDogs = [];
  final List<Dog> _givenAwayDogs = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Adoption App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainScreen(
        adoptedDogs: _adoptedDogs,
        givenAwayDogs: _givenAwayDogs,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final List<Dog> adoptedDogs;
  final List<Dog> givenAwayDogs;

  const MainScreen({
    super.key,
    required this.adoptedDogs,
    required this.givenAwayDogs,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(adoptedDogs: widget.adoptedDogs),
      AdoptedDogsPage(
        adoptedDogs: widget.adoptedDogs,
        givenAwayDogs: widget.givenAwayDogs,
      ),
      GivenAwayDogsPage(givenAwayDogs: widget.givenAwayDogs),
      const AboutPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type:
            BottomNavigationBarType.fixed, 
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopted'),
          BottomNavigationBarItem(
              icon: Icon(Icons.replay), label: 'Given Away'),
          BottomNavigationBarItem(
              icon: Icon(Icons.question_mark), label: 'About'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<Dog> adoptedDogs;

  const HomePage({super.key, required this.adoptedDogs});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedBreed;
  String? _dogImage;
  String _randomName = WordPair.random().asPascalCase;
  List<String> _breeds = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBreeds();
  }

  Future<void> _loadBreeds() async {
    setState(() => _isLoading = true);
    final response =
        await http.get(Uri.parse("https://dog.ceo/api/breeds/list/all"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _breeds = List<String>.from(data['message'].keys);
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load dog breeds');
    }
  }

  Future<void> _fetchBreedImage(String breed) async {
    final response = await http
        .get(Uri.parse("https://dog.ceo/api/breed/$breed/images/random"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _dogImage = data['message'];
        _randomName = WordPair.random().asPascalCase;
      });
    } else {
      throw Exception('Failed to load dog image');
    }
  }

  void _adoptDog() {
    if (_selectedBreed != null && _dogImage != null) {
      setState(() {
        widget.adoptedDogs.add(Dog(
            breed: _selectedBreed!, name: _randomName, imageUrl: _dogImage!));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Dog Adopted!")),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const SizedBox(height: 20), // Spacing from the top
        const Text(
          'Home',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10), // Spacing below the title
        Expanded(
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: _selectedBreed,
                        hint: const Text('Select a Dog Breed'),
                        onChanged: (String? breed) {
                          setState(() => _selectedBreed = breed);
                          if (breed != null) {
                            _fetchBreedImage(breed);
                          }
                        },
                        items: _breeds.map((breed) {
                          return DropdownMenuItem<String>(
                            value: breed,
                            child: Text(breed.toUpperCase()),
                          );
                        }).toList(),
                      ),
                      if (_dogImage != null) ...[
                        const SizedBox(height: 20),
                        Image.network(_dogImage!,
                            width: 300, height: 300, fit: BoxFit.cover),
                        const SizedBox(height: 10),
                        Text('Name: $_randomName',
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: _adoptDog, child: const Text("Adopt")),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () => _fetchBreedImage(_selectedBreed!),
                              child: const Text("Show Next"),
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
  );
}

}

class AdoptedDogsPage extends StatefulWidget {
  final List<Dog> adoptedDogs;
  final List<Dog> givenAwayDogs;

  const AdoptedDogsPage(
      {super.key, required this.adoptedDogs, required this.givenAwayDogs});

  @override
  State<AdoptedDogsPage> createState() => _AdoptedDogsPageState();
}

class _AdoptedDogsPageState extends State<AdoptedDogsPage> {

  void _giveAwayDog(int index) {
    setState(() {
      widget.givenAwayDogs.add(widget.adoptedDogs[index]);
      widget.adoptedDogs.removeAt(index);
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Adopted Dogs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              itemCount: widget.adoptedDogs.length,
              itemBuilder: (context, index) {
                final dog = widget.adoptedDogs[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            dog.imageUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dog.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dog.breed,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _giveAwayDog(index),
                          child: const Text(
                            "Give Away",
                            style: TextStyle(
                                color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}


}

class GivenAwayDogsPage extends StatelessWidget {
  final List<Dog> givenAwayDogs;

  const GivenAwayDogsPage({super.key, required this.givenAwayDogs});

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Given Away Dogs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView.builder(
              itemCount: givenAwayDogs.length,
              itemBuilder: (context, index) {
                final dog = givenAwayDogs[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            dog.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dog.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dog.breed,
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
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
          ),
        ),
      ],
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'About',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'My name is Ruby Ann Pacalso, 21 years old. 3rd Year BSIT student at Kings College of the Philippines.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    ),
  );
}

}
