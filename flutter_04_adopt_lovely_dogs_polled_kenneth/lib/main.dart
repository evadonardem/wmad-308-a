import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart' show WordPair;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'notification_widget.dart';

void main() {
  runApp(const MyApp());
}

class DogBreed {
  final String name;

  const DogBreed({required this.name});

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(
      name: json['name'] as String,
    );
  }
}

Future<List<DogBreed>> fetchDogBreeds() async {
  var dogBreedsEndpoint = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var breeds = (data['message'] as Map<String, dynamic>).keys.map(
      (key) => DogBreed(name: key.toUpperCase()),
    ).toList();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Orbitron', // Set the default font to Orbitron
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 0, 0)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
          bodyMedium: TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
          headlineMedium: TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
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
  String? notificationMessage;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showNotification(String message) {
    setState(() {
      notificationMessage = message;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        notificationMessage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                MyHomePage(
                    title: 'Homebound Hounds',
                    adoptedDogs: adoptedDogs,
                    showNotification: _showNotification),
                AdoptedDogsPage(
                    adoptedDogs: adoptedDogs,
                    giveAwayDogs: giveAwayDogs,
                    showNotification: _showNotification),
                GiveAwayPage(giveAwayDogs: giveAwayDogs, showNotification: _showNotification),
                const AboutPage(),
              ],
            ),
          ),
          if (notificationMessage != null)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: NotificationWidget(message: notificationMessage!),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets, color: Colors.white),
            label: 'Adopted Dogs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer, color: Colors.white),
            label: 'Give Away',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info, color: Colors.white),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        backgroundColor: Colors.transparent,
        onTap: _onItemTapped,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'About Homebound Hounds',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Homebound Hounds is an app designed to help you find and adopt your perfect canine companion. '
                'Browse through various dog breeds, view images, and adopt your favorite dogs. '
                'You can also give away dogs that you have adopted if you can no longer take care of them.\n\n'
                'Features:\n'
                '- Browse different dog breeds\n'
                '- View images of dogs\n'
                '- Adopt dogs\n'
                '- Give away dogs\n\n'
                'We hope you find your perfect furry friend with Homebound Hounds!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Orbitron'),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key, required this.title, required this.adoptedDogs, required this.showNotification});

  final String title;
  final List<AdoptedDog> adoptedDogs;
  final void Function(String) showNotification;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<DogBreed>> futureDogBreeds;
  DogBreed? selectedBreed;
  String? dogImageUrl;
  String? dogName;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  void _onBreedSelected(DogBreed? breed) async {
    if (breed != null) {
      setState(() {
        isLoading = true;
      });
      await _fetchNewDog(breed);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchNewDog(DogBreed breed) async {
    final imageUrl = await fetchDogImage(breed.name.toLowerCase());
    setState(() {
      selectedBreed = breed;
      dogImageUrl = imageUrl;
      dogName = WordPair.random().asPascalCase; // Ensure random name generation
    });
  }

  void _showAnotherDog() async {
    if (selectedBreed != null) {
      setState(() {
        isLoading = true;
      });
      final imageUrl = await fetchDogImage(selectedBreed!.name.toLowerCase());
      setState(() {
        dogImageUrl = imageUrl;
        dogName = WordPair.random().asPascalCase; // Change the dog name
        isLoading = false;
      });
    }
  }

  void _adoptDog() {
    if (selectedBreed != null && dogImageUrl != null && dogName != null) {
      setState(() {
        widget.adoptedDogs.add(AdoptedDog(
          breed: selectedBreed!.name,
          imageUrl: dogImageUrl!,
          name: dogName!,
        ));
      });
      widget.showNotification('You have adopted $dogName');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Select Dog Breeds',
                style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Orbitron'),
              ),
              FutureBuilder<List<DogBreed>>(
                future: futureDogBreeds,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
                    );
                  } else if (snapshot.hasData) {
                    return Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: DropdownButton<DogBreed>(
                        dropdownColor: const Color.fromARGB(255, 0, 0, 0),
                        value: selectedBreed,
                        items: snapshot.data!.map((DogBreed breed) {
                          return DropdownMenuItem<DogBreed>(
                            value: breed,
                            child: Center(
                              child: Text(
                                breed.name,
                                style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: _onBreedSelected,
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
                        underline: Container(
                          height: 2,
                          color: Colors.white,
                        ),
                      ),
                    );
                  } else {
                    return const Text(
                      'No data available',
                      style: TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
                    );
                  }
                },
              ),
              if (selectedBreed != null)
                Text(
                  'Selected Breed: ${selectedBreed!.name}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4.0,
                  ),
                )
              else if (dogImageUrl != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.width * 0.3,
                            child: dogImageUrl == null
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 4.0,
                                  )
                                : Image.network(
                                    dogImageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          if (isLoading)
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 4.0,
                            ),
                        ],
                      ),
                      Text(
                        'Name: $dogName',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _adoptDog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                            child: const Text('Adopt Me', style: TextStyle(fontFamily: 'Orbitron')),
                          ),
                          const SizedBox(width: 16.0),
                          ElevatedButton(
                            onPressed: _showAnotherDog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                            ),
                            child: const Text('Show Me Another Dog', style: TextStyle(fontFamily: 'Orbitron')),
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
    );
  }
}

class AdoptedDogsPage extends StatefulWidget {
  const AdoptedDogsPage(
      {super.key, required this.adoptedDogs, required this.giveAwayDogs, required this.showNotification});

  final List<AdoptedDog> adoptedDogs;
  final List<GiveAwayDog> giveAwayDogs;
  final void Function(String) showNotification;

  @override
  _AdoptedDogsPageState createState() => _AdoptedDogsPageState();
}

class _AdoptedDogsPageState extends State<AdoptedDogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            const Text(
              'Adopted Dogs',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: widget.adoptedDogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No adopted dogs',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Orbitron'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.adoptedDogs.length,
                      itemBuilder: (context, index) {
                        final dog = widget.adoptedDogs[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(dog.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Orbitron')),
                            subtitle: Text(dog.breed, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Orbitron')),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  widget.giveAwayDogs.add(GiveAwayDog(
                                    breed: dog.breed,
                                    imageUrl: dog.imageUrl,
                                    name: dog.name,
                                  ));
                                  widget.adoptedDogs.removeAt(index);
                                });
                                widget.showNotification('You have given away ${dog.name}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                              ),
                              icon: const FaIcon(FontAwesomeIcons.gift, size: 16),
                              label: const Text('Give Away', style: TextStyle(fontFamily: 'Orbitron')),
                            ),
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

class GiveAwayPage extends StatefulWidget {
  const GiveAwayPage({super.key, required this.giveAwayDogs, required this.showNotification});

  final List<GiveAwayDog> giveAwayDogs;
  final void Function(String) showNotification;

  @override
  _GiveAwayPageState createState() => _GiveAwayPageState();
}

class _GiveAwayPageState extends State<GiveAwayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            const Text(
              'Give Away Dogs',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: widget.giveAwayDogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No given away dogs',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Orbitron'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.giveAwayDogs.length,
                      itemBuilder: (context, index) {
                        final dog = widget.giveAwayDogs[index];
                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            leading: Image.network(dog.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(dog.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Orbitron')),
                            subtitle: Text(dog.breed, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Orbitron')),
                            trailing: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  widget.giveAwayDogs.removeAt(index);
                                });
                                widget.showNotification('You have removed ${dog.name}');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                              ),
                              icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                              label: const Text('Remove', style: TextStyle(fontFamily: 'Orbitron')),
                            ),
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