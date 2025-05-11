import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dog',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: Colors.brown[800]!,
          secondary: Colors.orange[600]!,
          surface: Colors.grey[200]!,
          background: Colors.grey[300]!,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 18),
        ),
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
  late Future<List<Dog>> futureDogs;
  Future<Dog>? futureSelectedDog;
  bool hasSelection = false, isLoadingImage = false, showDropdown = false;
  Dog? selectedDog;
  List<Dog> filteredDogs = [], likedDogs = [];
  int _selectedIndex = 0;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureDogs = fetchDogs();
    futureDogs.then((dogs) => setState(() => filteredDogs = dogs));
  }

  void handleDogSelection(Dog dog) {
    setState(() {
      hasSelection = true;
      isLoadingImage = true;
      searchController.text = dog.breed.toUpperCase();
      showDropdown = false;
      futureSelectedDog = fetchRandomDogImage(dog.breed).then((dog) {
        setState(() {
          isLoadingImage = false;
          selectedDog = dog;
        });
        return dog;
      });
    });
  }

  void likeDog(Dog dog) {
    setState(() {
      if (!likedDogs.any((d) => d.imageUrl == dog.imageUrl && d.name == dog.name)) {
        likedDogs.add(dog);
      }
    });
  }

  void fetchNextDog() {
    if (selectedDog != null) {
      setState(() {
        isLoadingImage = true;
        futureSelectedDog = fetchRandomDogImage(selectedDog!.breed).then((dog) {
          setState(() {
            isLoadingImage = false;
            selectedDog = dog;
          });
          return dog;
        });
      });
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  List<Widget> _buildPages() {
    return [
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: Center(
            child: Column(
              children: <Widget>[
                const Text(
                  "🐶 ANIMAL DOG SHELTER 🐶",
                  style: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                const SizedBox(height: 20),
                const Text("Select a Dog", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search...",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_drop_down),
                        onPressed: () => setState(() => showDropdown = !showDropdown),
                      ),
                    ),
                    onChanged: (query) {
                      futureDogs.then((dogs) {
                        setState(() {
                          filteredDogs = dogs.where((dog) => dog.breed.toLowerCase().contains(query.toLowerCase())).toList();
                          showDropdown = true;
                        });
                      });
                    },
                  ),
                ),
                if (showDropdown)
                  SizedBox(
                    width: 300,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredDogs.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(filteredDogs[index].breed.toUpperCase()),
                        onTap: () => handleDogSelection(filteredDogs[index]),
                      ),
                    ),
                  ),
                if (hasSelection)
                  isLoadingImage
                      ? const CircularProgressIndicator()
                      : FutureBuilder<Dog>(
                          future: futureSelectedDog,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Column(
                                children: [
                                  Image.network(snapshot.data!.imageUrl, width: 300, height: 400, fit: BoxFit.cover),
                                  Text(snapshot.data!.name.toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => likeDog(snapshot.data!),
                                        child: const Text("Adopt Me"),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: fetchNextDog,
                                        child: const Text("Next"),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          }),
              ],
            ),
          ),
        ),
      ),
      _buildGridPage(likedDogs),
      const AboutPage(),
    ];
  }

 Widget _buildGridPage(List<Dog> dogs) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 20), // Adds top margin
      child: SizedBox(
        width: 350,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: dogs.length,
          itemBuilder: (context, index) => Card(
            child: Column(
              children: [
                Image.network(dogs[index].imageUrl, width: 100, height: 100, fit: BoxFit.cover),
                Text(dogs[index].breed, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(dogs[index].name),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPages().elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Adopted'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            "Welcome to Animal Dog Shelter!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Text("Our goal is to help dogs find loving homes.", style: TextStyle(fontSize: 20)),
          ),
          Image.network('https://placedog.net/300', width: 300),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('https://placedog.net/200', width: 150),
              const SizedBox(width: 10),
              Image.network('https://placedog.net/201', width: 150),
            ],
          ),
        ],
      ),
    );
  }
}
class Dog {
  final String breed, name, imageUrl;
  Dog({required this.breed, required this.name, required this.imageUrl});
  factory Dog.withRandomName(String breed, String imageUrl) => Dog(breed: breed, name: WordPair.random().join(), imageUrl: imageUrl);
}

Future<List<Dog>> fetchDogs() async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
  final data = jsonDecode(response.body);
  return data['message'].keys.map<Dog>((breed) => Dog(breed: breed, name: WordPair.random().join(), imageUrl: '')).toList();
}

Future<Dog> fetchRandomDogImage(String breed) async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
  return Dog.withRandomName(breed, jsonDecode(response.body)['message']);
}