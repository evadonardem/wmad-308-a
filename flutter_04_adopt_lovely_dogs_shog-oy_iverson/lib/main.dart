import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class Dog {
  final String name;
  final String breed;
  final String imageUrl;

  Dog({required this.name, required this.breed, required this.imageUrl});

  factory Dog.fromJson(Map<String, dynamic> json) {
    try {
      final name = json['name'] as String;
      final breed = json['breed'] as String;
      final imageUrl = json['imageUrl'] as String;

      return Dog(name: name, breed: breed, imageUrl: imageUrl);
    } catch (e) {
      throw FormatException('Failed to load DOG! $e');
    }
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

    Dog dog = Dog.fromJson({
      'name': dogName.asPascalCase,
      'breed': breed,
      'imageUrl': data['message'],
    });

    return dog;
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  List<Dog> adoptedDogs = [];
  List<Dog> giveAwayDogs = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void adoptDog(Dog dog, BuildContext context) {
    if (!adoptedDogs.any((adoptedDog) => adoptedDog.imageUrl == dog.imageUrl)) {
      setState(() {
        adoptedDogs.add(dog);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dog.name} has been adopted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
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
    return MaterialApp(
      title: 'Dog Breeds',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 4, 150, 77),
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        body:
            [
              MyHomePage(adoptDog: adoptDog),
              AdoptedDogsPage(
                adoptedDogs: adoptedDogs,
                giveAwayDog: giveAwayDog,
              ),
              GiveAwayPage(giveAwayDogs: giveAwayDogs),
              AboutPage(),
            ][_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets),
              label: 'Adopted Dogs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'Give Away',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color.fromARGB(255, 4, 150, 77),
          unselectedItemColor: Colors.black,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.adoptDog});
  final Function(Dog, BuildContext) adoptDog;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<String>> futureDogBreeds;
  Dog? selectedDog;
  String? selectedBreed;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void fetchDogData(String breed) async {
    final dog = await fetchDog(breed);
    setState(() {
      selectedDog = dog;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "Dog Breeds List", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              "Welcome to Dating Dogs. Adopt a Dog of your LIKING!", 
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16), 
            FutureBuilder(
              future: futureDogBreeds,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return DropdownButton<String>(
                    hint: const Text('Select a breed'),
                    value: selectedBreed,
                    items:
                        snapshot.requireData
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
            ),
            
            const SizedBox(height: 20),
            if (selectedDog != null) ...[
              CachedNetworkImage(
                imageUrl: selectedDog!.imageUrl,
                height: 340,
                width: 340,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
              const SizedBox(height: 10),
              Text(
                'Name: ${selectedDog!.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDog != null) {
                        widget.adoptDog(selectedDog!, context);
                      }
                    },
                    child: const Text('Adopt'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedBreed != null) {
                        fetchDogData(selectedBreed!);
                      }
                    },
                    child: const Text('Show Next'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AdoptedDogsPage extends StatefulWidget {
  final List<Dog> adoptedDogs;
  final Function(Dog) giveAwayDog;

  const AdoptedDogsPage({
    super.key,
    required this.adoptedDogs,
    required this.giveAwayDog,
  });

  @override
  _AdoptedDogsPageState createState() => _AdoptedDogsPageState();
}

class _AdoptedDogsPageState extends State<AdoptedDogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adopted Dogs')),
      body:
          widget.adoptedDogs.isEmpty
              ? const Center(child: Text('No adopted dogs yet.'))
              : ListView.builder(
                itemCount: widget.adoptedDogs.length,
                itemBuilder: (context, index) {
                  final dog = widget.adoptedDogs[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: dog.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CircularProgressIndicator(),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.error),
                      ),
                      title: Text(
                        dog.name,
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Text('Breed: ${dog.breed}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            widget.giveAwayDog(dog);
                          });
                        },
                        child: const Text('Give Away'),
                      ),
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
      body:
          giveAwayDogs.isEmpty
              ? const Center(child: Text('No dogs for give away.'))
              : ListView.builder(
                itemCount: giveAwayDogs.length,
                itemBuilder: (context, index) {
                  final dog = giveAwayDogs[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: dog.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => const CircularProgressIndicator(),
                        errorWidget:
                            (context, url, error) => const Icon(Icons.error),
                      ),
                      title: Text(
                        dog.name,
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Text('Breed: ${dog.breed}'),
                    ),
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
      appBar: AppBar(
        title: const Text('About Dating Dogs'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🐶 Dating Dogs BY IVERSON SHOG_OY',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Find Your Perfect Canine Companion!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              const Text(
                'Welcome to Dating Dogs, the ultimate platform to help you find and adopt the perfect furry friend. Whether you’re looking for a playful pup, a loyal companion, or a gentle senior dog, we make the process of adopting easy and enjoyable.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                '🎯 Our Mission',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'At Dating Dogs, we believe that every dog deserves a loving home. Our mission is to connect dogs in need with compassionate adopters, making adoption a seamless and heartwarming experience.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                '📌 How It Works',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                '1️⃣ Browse Breeds – Explore different dog breeds and find one that suits your lifestyle.\n'
                '2️⃣ Select & Match – Choose a breed and let us help you discover available dogs.\n'
                '3️⃣ Adopt with Ease – With just a few clicks, begin the journey of welcoming a new best friend into your home.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                '💖 Why Choose Dating Dogs?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                '✔ Wide Variety of Breeds – From playful Labradors to elegant Huskies, find your ideal match.\n'
                '✔ Easy-to-Use Interface – A simple and user-friendly experience for all dog lovers.\n'
                '✔ Trusted Adoptions – We work with reputable shelters and breeders to ensure responsible adoptions.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                '🌍 Join Our Community!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Become a part of a loving community that celebrates dog adoption. Follow us for heartwarming adoption stories, training tips, and more!',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                '📍 Location: Available nationwide\n'
                '📩 Contact Us: support@datingdogs.com',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  '🐕 Adopt. Love. Repeat. BY IVERSON SHOG_OY❤️',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
