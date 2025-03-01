import 'dart:convert';
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

  factory Dog.fromJson(String breed, Map<String, dynamic> json) {
    return Dog(name: WordPair.random().asPascalCase, breed: breed, imageUrl: json['message']);
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

Future<Dog> fetchRandomDog(String breed) async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    Dog dog = Dog.fromJson(breed, data);
    return dog;
  } else {
    throw Exception('Failed to load dog image');
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <Dog>[];
  var giveaway = <Dog>[];

  void toggleFavorite(Dog dog) {
    if (favorites.contains(dog)) {
      favorites.remove(dog);
    } else {
      favorites.add(dog);
    }
    notifyListeners();
  }

  bool isFavorite(Dog dog) {
    return favorites.contains(dog);
  }

  void addToGiveaway(Dog dog) {
    if (!giveaway.contains(dog)) {
      giveaway.add(dog);
      favorites.remove(dog);
    }
    notifyListeners();
  }

  void deleteDog(Dog dog) {
    favorites.remove(dog);
    notifyListeners();
  }

  void deleteFromGiveaway(Dog dog) {
    giveaway.remove(dog);
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Breeds',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Adopt a dog'),
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
  Dog? selectedDog;
  String? selectedBreed;
  late Future<List<String>> futureDogBreeds;
  final MyAppState appState = MyAppState();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void _fetchDogByBreed(String breed) async {
    final dog = await fetchRandomDog(breed);
    setState(() {
      selectedDog = dog;
    });
  }

  void _fetchRandomDog() async {
    if (selectedBreed != null) {
      final dog = await fetchRandomDog(selectedBreed!);
      setState(() {
        selectedDog = dog;
      });
    }
  }

  void _addToFavorites() {
    if (selectedDog != null) {
      appState.toggleFavorite(selectedDog!);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getBodyContent() {
    switch (_selectedIndex) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FutureBuilder(
                future: futureDogBreeds,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return DropdownButton<String>(
                      hint: const Text('Choose a breed'),
                      value: selectedBreed,
                      items: snapshot.requireData
                          .map((breed) => DropdownMenuItem(
                                value: breed,
                                child: Text(breed.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedBreed = newValue;
                        });
                        _fetchDogByBreed(newValue!);
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
                Image.network(selectedDog!.imageUrl, height: 200, width: 200, fit: BoxFit.cover),
                const SizedBox(height: 10),
                Text(
                  'Dog Name: ${selectedDog!.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _fetchRandomDog,
                  child: const Text('Get Another Random Dog'),
                ),
                const SizedBox(height: 20),
                IconButton(
                  icon: Icon(
                    appState.isFavorite(selectedDog!) ? Icons.favorite : Icons.favorite_border,
                    color: appState.isFavorite(selectedDog!) ? Colors.red : Colors.grey,
                  ),
                  onPressed: _addToFavorites,
                  iconSize: 40,
                ),
              ],
            ],
          ),
        );
      case 1:
        return FavoritesScreen(favorites: appState.favorites, appState: appState);
      case 2:
        return GiveawayScreen(giveaway: appState.giveaway, appState: appState);
      case 3:
        return AboutMeScreen();
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(widget.title),
      ),
      body: _getBodyContent(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.blue,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Adopted Dogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell),
            label: 'Giveaway',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About Me',
          ),
        ],
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<Dog> favorites;
  final MyAppState appState;

  const FavoritesScreen({super.key, required this.favorites, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final dog = favorites[index];
        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(dog.name),
            subtitle: Text('Breed: ${dog.breed}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.sell),
                  onPressed: () {
                    appState.addToGiveaway(dog);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    appState.deleteDog(dog);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GiveawayScreen extends StatelessWidget {
  final List<Dog> giveaway;
  final MyAppState appState;

  const GiveawayScreen({super.key, required this.giveaway, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: giveaway.length,
      itemBuilder: (context, index) {
        final dog = giveaway[index];
        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
            title: Text(dog.name),
            subtitle: Text('Breed: ${dog.breed}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                appState.deleteFromGiveaway(dog);
              },
            ),
          ),
        );
      },
    );
  }
}

class AboutMeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text(
            'Dudz Adopt a Dog',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'This app showcases adoption for dogs. You can choose a dog you want to adopt and if youre tired of them you can give them away!!!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
