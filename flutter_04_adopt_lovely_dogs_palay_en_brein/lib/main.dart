import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() => runApp(const MyApp());

class Dog {
  final String name, breed, imageUrl;
  Dog({required this.name, required this.breed, required this.imageUrl});

  factory Dog.fromJson(Map<String, dynamic> json) => Dog(
        name: json['name'],
        breed: json['breed'],
        imageUrl: json['imageUrl'],
      );
}

Future<List<String>> fetchBreeds() async {
  final res = await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
  if (res.statusCode == 200) {
    return (jsonDecode(res.body)['message'] as Map<String, dynamic>).keys.toList();
  }
  throw Exception('Failed to load breeds');
}

Future<Dog> fetchDog(String breed) async {
  final res = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));
  if (res.statusCode == 200) {
    return Dog.fromJson({
      'name': WordPair.random().asPascalCase,
      'breed': breed,
      'imageUrl': jsonDecode(res.body)['message'],
    });
  }
  throw Exception('Failed to load dog');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  List<Dog> adoptedDogs = [], giveAwayDogs = [];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  void adoptDog(Dog dog) {
    if (!adoptedDogs.any((d) => d.imageUrl == dog.imageUrl)) {
      setState(() => adoptedDogs.add(dog));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dog.name} has been adopted!'),
          duration: Duration(seconds: 2),
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('DOG ADOPTION APP'),
          backgroundColor: Colors.orange,
        ),
        body: [
          HomePage(adoptDog: adoptDog),
          DogsPage(dogs: adoptedDogs, title: 'Adopted Dogs', action: giveAwayDog, actionLabel: 'Give Away'),
          DogsPage(dogs: giveAwayDogs, title: 'Given Away Dogs'),
          AboutPage(),
        ][_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopted'),
            BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Given Away'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(Dog) adoptDog;
  const HomePage({super.key, required this.adoptDog});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedBreed;
  Dog? currentDog;
  List<String> breeds = [];

  @override
  void initState() {
    super.initState();
    fetchBreeds().then((value) => setState(() => breeds = value));
  }

  void getNewDog() async {
    if (selectedBreed != null) {
      Dog newDog = await fetchDog(selectedBreed!);
      setState(() => currentDog = newDog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Dog Adoption App',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          DropdownButton<String>(
            value: selectedBreed,
            hint: Text('Select a Breed'),
            isExpanded: true,
            items: breeds.map((breed) {
              return DropdownMenuItem(
                value: breed,
                child: Text(breed.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedBreed = value),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: getNewDog,
            child: Text('Show & Next Dog'),
          ),
          if (currentDog != null) ...[
            SizedBox(height: 20),
            CachedNetworkImage(imageUrl: currentDog!.imageUrl, height: 200),
            Text(currentDog!.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(currentDog!.breed, style: TextStyle(fontSize: 16)),
            ElevatedButton(
              onPressed: () => widget.adoptDog(currentDog!),
              child: Text('Adopt'),
            ),
          ],
        ],
      ),
    );
  }
}


class DogsPage extends StatelessWidget {
  final List<Dog> dogs;
  final String title;
  final Function(Dog)? action;
  final String? actionLabel;
  DogsPage({required this.dogs, required this.title, this.action, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: dogs.map((dog) => ListTile(
        leading: CachedNetworkImage(imageUrl: dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
        title: Text(dog.name),
        subtitle: Text(dog.breed),
        trailing: action != null ? ElevatedButton(
          onPressed: () => action!(dog),
          child: Text(actionLabel!),
        ) : null,
      )).toList(),
    );
  }
}

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('About the Dog Adoption App', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(
              'This app helps users adopt lovely dogs by selecting their favorite breed. '
              'Users can also view their adopted and given-away dogs.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
