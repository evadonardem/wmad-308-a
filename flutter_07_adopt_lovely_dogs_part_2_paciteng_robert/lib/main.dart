import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart' show WordPair;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await initializeDatabase();
  runApp(const MyApp());
}

late Database database;

Future<void> initializeDatabase() async {
  final dbPath = await getDatabasesPath();
  database = await openDatabase(
    join(dbPath, 'dogs.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE adopted_dogs(id INTEGER PRIMARY KEY, breed TEXT, imageUrl TEXT, name TEXT)',
      ).then((_) {
        return db.execute(
          'CREATE TABLE give_away_dogs(id INTEGER PRIMARY KEY, breed TEXT, imageUrl TEXT, name TEXT)',
        );
      });
    },
    version: 1,
  );
}

Future<void> saveAdoptedDog(AdoptedDog dog) async {
  try {
    await database.insert(
      'adopted_dogs',
      {'breed': dog.breed, 'imageUrl': dog.imageUrl, 'name': dog.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    debugPrint('Error saving adopted dog: $e');
  }
}

Future<List<AdoptedDog>> getAdoptedDogs() async {
  final List<Map<String, dynamic>> maps = await database.query('adopted_dogs');
  return List.generate(maps.length, (i) {
    return AdoptedDog(
      breed: maps[i]['breed'],
      imageUrl: maps[i]['imageUrl'],
      name: maps[i]['name'],
    );
  });
}

Future<void> deleteAdoptedDog(String name) async {
  await database.delete(
    'adopted_dogs',
    where: 'name = ?',
    whereArgs: [name],
  );
}

Future<void> saveGiveAwayDog(GiveAwayDog dog) async {
  await database.insert(
    'give_away_dogs',
    {'breed': dog.breed, 'imageUrl': dog.imageUrl, 'name': dog.name},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<GiveAwayDog>> getGiveAwayDogs() async {
  final List<Map<String, dynamic>> maps = await database.query('give_away_dogs');
  return List.generate(maps.length, (i) {
    return GiveAwayDog(
      breed: maps[i]['breed'],
      imageUrl: maps[i]['imageUrl'],
      name: maps[i]['name'],
    );
  });
}

class DogBreed {
  final String name;
  const DogBreed({required this.name});
  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(name: json['name'] as String);
  }
}

Future<List<DogBreed>> fetchDogBreeds() async {
  var dogBreedsEndpoint = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(dogBreedsEndpoint));
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var breeds = (data['message'] as Map<String, dynamic>)
        .keys
        .map((key) => DogBreed(name: key.toUpperCase()))
        .toList();
    return breeds;
  } else {
    throw Exception('FAILED to load dog breeds');
  }
}

Future<String> fetchDogImage(String breed) async {
  var dogImageEndpoint = "https://dog.ceo/api/breed/$breed/images/random";
  final response = await http.get(Uri.parse(dogImageEndpoint));
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('FAILED to load dog image');
  }
}

class AdoptedDog {
  final String breed;
  final String imageUrl;
  final String name;
  AdoptedDog({required this.breed, required this.imageUrl, required this.name});
}

class GiveAwayDog {
  final String breed;
  final String imageUrl;
  final String name;
  GiveAwayDog({required this.breed, required this.imageUrl, required this.name});
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void _showNotification(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey, 
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.orange[50],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
          headlineMedium: TextStyle(color: Colors.black),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  List<AdoptedDog> adoptedDogs = [];
  List<GiveAwayDog> giveAwayDogs = [];
  @override
  void initState() {
    super.initState();
    initializeDatabase().then((_) async {
      adoptedDogs = await getAdoptedDogs();
      giveAwayDogs = await getGiveAwayDogs();
      setState(() {});
    });
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _moveToGiveAway(AdoptedDog dog) async {
    final giveAwayDog = GiveAwayDog(
      breed: dog.breed,
      imageUrl: dog.imageUrl,
      name: dog.name,
    );
    await saveGiveAwayDog(giveAwayDog);
    await deleteAdoptedDog(dog.name);
    setState(() {
      adoptedDogs.remove(dog); 
      giveAwayDogs.add(giveAwayDog);
    });
    _showNotification('Dog Given away succesfully!'); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            MyHomePage(title: 'ADOPT A DOG', adoptedDogs: adoptedDogs),
            AdoptedDogsPage(
              adoptedDogs: adoptedDogs,
              giveAwayDogs: giveAwayDogs,
              onMoveToGiveAway: _moveToGiveAway, 
            ),
            GiveAwayPage(giveAwayDogs: giveAwayDogs),
            const AboutPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopted Dogs'),
          BottomNavigationBarItem(icon: Icon(Icons.local_offer), label: 'Give Away'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.blue[800],
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Welcome to the Dog Adoption App! Here you can explore various dog breeds, view random dog images, and even adopt or give away a dog.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black54,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Our mission is to help connect loving homes with adorable dogs. Whether you are looking to adopt a dog or give one away, this app aims to make the process simple and fun!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Built with Flutter and powered by CEO Robert Paciteng Jr., the app fetches a wide variety of dog breeds and random images to help you find your perfect pet companion.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.adoptedDogs});
  final String title;
  final List<AdoptedDog> adoptedDogs;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<DogBreed>> futureDogBreeds;
  DogBreed? selectedBreed;
  String? dogImageUrl;
  String? dogName;
  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }
  void _onBreedSelected(DogBreed? breed) async {
    if (breed != null) {
      await _fetchNewDog(breed);
    }
  }
  Future<void> _fetchNewDog(DogBreed breed) async {
    final imageUrl = await fetchDogImage(breed.name.toLowerCase());
    setState(() {
      selectedBreed = breed;
      dogImageUrl = imageUrl;
      dogName = WordPair.random().asPascalCase;
    });
  }
  void _showAnotherDog() async {
    if (selectedBreed != null) {
      final imageUrl = await fetchDogImage(selectedBreed!.name.toLowerCase());
      setState(() {
        dogImageUrl = imageUrl;
        dogName = WordPair.random().asPascalCase;
      });
    }
  }
  void _adoptDog() async {
    if (selectedBreed != null && dogImageUrl != null && dogName != null) {
      if (widget.adoptedDogs.any((dog) => dog.name == dogName)) {
        _showNotification('Dog already adopted!'); 
        return;
      }
      final newDog = AdoptedDog(
        breed: selectedBreed!.name,
        imageUrl: dogImageUrl!,
        name: dogName!,
      );
      await saveAdoptedDog(newDog);
      setState(() {
        widget.adoptedDogs.add(newDog);
      });
      _showNotification('Dog adopted successfully!'); 
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: <Widget>[
                Text(widget.title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 20),
                FutureBuilder<List<DogBreed>>(
                  future: futureDogBreeds,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 800, 
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                decoration: BoxDecoration(
                                  color: Colors.blue[900],
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: DropdownButton<DogBreed>(
                                  value: selectedBreed,
                                  hint: const Text(
                                    "Select Dog Breed Here",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  dropdownColor: Colors.blue[800],
                                  style: const TextStyle(color: Colors.white),
                                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                  items: snapshot.data!.map((DogBreed breed) {
                                    return DropdownMenuItem<DogBreed>(
                                      value: breed,
                                      child: Text(breed.name),
                                    );
                                  }).toList(),
                                  onChanged: _onBreedSelected,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return const Text('No data available');
                    }
                  },
                ),
                if (selectedBreed != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Text('Selected Breed: ${selectedBreed!.name}'),
                  ),
                if (dogImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16.0),
                          child: Image.network(dogImageUrl!, width: 350, height: 250, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            'Name: $dogName',
                            style: const TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _adoptDog,
                              child: const Text('Adopt Me'),
                            ),
                            ElevatedButton(
                              onPressed: _showAnotherDog,
                              child: const Text('Show Me Another Dog'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdoptedDogsPage extends StatelessWidget {
  const AdoptedDogsPage({super.key, required this.adoptedDogs, required this.giveAwayDogs, required this.onMoveToGiveAway});
  final List<AdoptedDog> adoptedDogs;
  final List<GiveAwayDog> giveAwayDogs;
  final void Function(AdoptedDog dog) onMoveToGiveAway;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adopted Dogs')),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: adoptedDogs.length,
        itemBuilder: (context, index) {
          final dog = adoptedDogs[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      dog.imageUrl,
                      fit: BoxFit.fill,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Name:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(dog.name, style: const TextStyle(color: Colors.black)),
                      const SizedBox(height: 5),
                      const Text("Breed:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(dog.breed, style: const TextStyle(color: Colors.black)),
                      IconButton(
                        icon: const Icon(Icons.local_offer, color: Colors.black),
                        onPressed: () => onMoveToGiveAway(dog), 
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GiveAwayPage extends StatelessWidget {
  const GiveAwayPage({super.key, required this.giveAwayDogs});
  final List<GiveAwayDog> giveAwayDogs;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Give Away Dogs')),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: giveAwayDogs.length,
        itemBuilder: (context, index) {
          final dog = giveAwayDogs[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      dog.imageUrl,
                      fit: BoxFit.fill,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Name:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(dog.name, style: const TextStyle(color: Colors.black)),
                      const SizedBox(height: 5),
                      const Text("Breed:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      Text(dog.breed, style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}