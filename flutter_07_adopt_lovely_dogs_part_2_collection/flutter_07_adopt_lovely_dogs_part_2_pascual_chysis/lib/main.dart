import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'database/database_helper.dart';
import 'database/database_init.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi; 
  WidgetsFlutterBinding.ensureInitialized();
  await initDatabase(); 
  runApp(const NavigationBarApp());
}

class NavigationBarApp extends StatelessWidget {
  const NavigationBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Color(0xFFF8BBD0), // Light pink
          secondary: Color(0xFFF48FB1), // Slightly darker pink
          surface: Color(0xFFFFEBEE), // Very light pink
          background: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF8BBD0),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF48FB1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
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
  List<BreedDog> adoptedDogs = [];
  List<BreedDog> givenAwayDogs = [];
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = true;
  bool _isEditing = false;
  BreedDog? _editingDog;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home, color: Colors.pink),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.pets, color: Colors.pink),
            icon: Icon(Icons.pets_outlined),
            label: 'Adopt',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.handshake, color: Colors.pink),
            icon: Icon(Icons.handshake_outlined),
            label: 'Give Away',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.info, color: Colors.pink),
            icon: Icon(Icons.info_outline),
            label: 'About',
          ),
        ],
      ),
      body: <Widget>[
        HomePage(onAdopted: (dog) async {
          final Map<String, dynamic> dogMap = await dog.toMap();
          await _dbHelper.insertDog(dogMap);
          setState(() {
            adoptedDogs.add(dog);
          });
        }),

        AdoptPage(
          adoptedDogs: adoptedDogs,
          onGiveAway: (dog) {
            setState(() {
              adoptedDogs.remove(dog);
              givenAwayDogs.add(dog);
              currentPageIndex = 2; 
            });
          },
        ),

        MessagesPage(givenAwayDogs: givenAwayDogs),

        AboutPage(),
      ][currentPageIndex],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Hello!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'My name is Jezreel Douglas',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Dog Adoption App',
                style: TextStyle(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesPage extends StatelessWidget {
  final List<BreedDog> givenAwayDogs;

  const MessagesPage({Key? key, required this.givenAwayDogs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Given Away Dogs'),
        centerTitle: true,
      ),
      body: givenAwayDogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sentiment_satisfied_alt,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No dogs given away yet!',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.75,
              ),
              padding: const EdgeInsets.all(16.0),
              itemCount: givenAwayDogs.length,
              itemBuilder: (context, index) {
                final dog = givenAwayDogs[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12)),
                          child: FutureBuilder<BreedImage>(
                            future: dog.image,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                );
                              } else if (snapshot.hasData) {
                                return Image.network(
                                  snapshot.data!.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              }
                              return Center(
                                child: Icon(
                                  Icons.error,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              dog.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              dog.breed.name,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text(
                                'Given Away',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Theme.of(context).colorScheme.secondary,
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

class HomePage extends StatefulWidget {
  final Function(BreedDog) onAdopted;

  const HomePage({Key? key, required this.onAdopted}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Breed>> futureBreeds;
  late BreedDog selectedBreedDog;
  bool hasSelection = false;
  Future<BreedImage>? futureSelectedImageUrl;

  @override
  void initState() {
    super.initState();
    futureBreeds = fetchBreeds();
    selectedBreedDog = BreedDog(name: "", breed: Breed(name: ""), image: Future.value(BreedImage(imageUrl: "")));
  }

  void handleBreedSelection(Breed breed) {
    setState(() {
      final wordPair = WordPair.random().join("");
      futureSelectedImageUrl = fetchRandomAnimalFromBreed(breed.name);
      hasSelection = true;
      selectedBreedDog = BreedDog(
        name: wordPair,
        breed: breed,
        image: futureSelectedImageUrl!,
      );
    });
  }

  void handleAdopt() {
    if (selectedBreedDog.name.isEmpty || selectedBreedDog.breed.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No image or breed selected for adoption!"),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
      return;  
    }

    widget.onAdopted(selectedBreedDog);
    setState(() {
      hasSelection = false;
    });
  }

  void handleNext() {
    setState(() {
      selectedBreedDog = BreedDog(
        name: "",
        breed: Breed(name: ""),
        image: Future.value(BreedImage(imageUrl: "")),
      );
      futureSelectedImageUrl = null;
      hasSelection = false;
    });

    futureBreeds.then((breeds) {
      final breedList = breeds ?? [];
      if (breedList.isNotEmpty) {
        final randomBreed = breedList[Random().nextInt(breedList.length)];

        futureSelectedImageUrl = fetchRandomAnimalFromBreed(randomBreed.name);

        setState(() {
          selectedBreedDog = BreedDog(
            name: WordPair.random().join(""),
            breed: randomBreed,
            image: futureSelectedImageUrl!,
          );
          hasSelection = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          "Select a Dog Breed",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        SizedBox(height: 16),
                        FutureBuilder<List<Breed>>(
                          future: futureBreeds,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                '${snapshot.error}',
                                style: TextStyle(color: Colors.red),
                              );
                            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              var breeds = snapshot.data!;
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                constraints: BoxConstraints(maxWidth: 250),
                                child: DropdownButton<Breed>(
                                  isExpanded: true,
                                  underline: SizedBox(),
                                  items: breeds
                                      .map((breed) => DropdownMenuItem(
                                            value: breed,
                                            child: Text(
                                              breed.name.toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) handleBreedSelection(value);
                                  },
                                  hint: Text(
                                    'Select a breed',
                                    style: TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Text(
                              "No breeds found.",
                              style: TextStyle(color: Colors.black54),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasSelection)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          FutureBuilder<BreedImage>(
                            future: futureSelectedImageUrl,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                );
                              } else if (snapshot.hasError) {
                                return Column(
                                  children: [
                                    Icon(
                                      Icons.error,
                                      size: 48,
                                      color: Colors.red,
                                    ),
                                    Text(
                                      'Error loading image',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                );
                              } else if (snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    snapshot.data!.imageUrl,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }
                              return SizedBox();
                            },
                          ),
                          SizedBox(height: 16),
                          Text(
                            selectedBreedDog.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          Text(
                            selectedBreedDog.breed.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: handleAdopt,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.pets, size: 18),
                                    SizedBox(width: 8),
                                    Text("Adopt"),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: handleNext,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Theme.of(context).colorScheme.secondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.skip_next, size: 18),
                                    SizedBox(width: 8),
                                    Text("Next"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class AdoptPage extends StatefulWidget {
  final List<BreedDog> adoptedDogs;
  final Function(BreedDog) onGiveAway;

  const AdoptPage({Key? key, required this.adoptedDogs, required this.onGiveAway}) : super(key: key);

  @override
  _AdoptPageState createState() => _AdoptPageState();
}

class _AdoptPageState extends State<AdoptPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<BreedDog> _adoptedDogs = [];
  bool _isLoading = true;
  bool _isEditing = false;
  BreedDog? _editingDog;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> dogs = await _dbHelper.queryAllDogs();
      setState(() {
        _adoptedDogs = dogs.map((dog) => BreedDog.fromMap(dog)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dogs: ${e.toString()}')),
      );
    }
  }

  Future<void> _addDog(BreedDog dog) async {
    try {
      await _dbHelper.insertDog(await dog.toMap());
      await _loadDogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding dog: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateDog(BreedDog dog) async {
    try {
      await _dbHelper.updateDog(await dog.toMap());
      await _loadDogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating dog: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteDog(int id) async {
    try {
      await _dbHelper.deleteDog(id);
      await _loadDogs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting dog: ${e.toString()}')),
      );
    }
  }

  void _startEditing(BreedDog dog) {
    setState(() {
      _isEditing = true;
      _editingDog = dog;
      _nameController.text = dog.name;
    });
  }

  Future<void> _handleEditComplete() async {
    if (_nameController.text.trim().isNotEmpty && _editingDog != null) {
      final updatedDog = BreedDog(
        id: _editingDog!.id,
        name: _nameController.text.trim(),
        breed: _editingDog!.breed,
        image: _editingDog!.image,
        adoptedDate: _editingDog!.adoptedDate,
      );
      await _updateDog(updatedDog);
      setState(() {
        _isEditing = false;
        _editingDog = null;
        _nameController.clear();
      });
    }
  }

  void _handleDelete(BreedDog dog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${dog.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (dog.id != null) {
                await _deleteDog(dog.id!);
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleGiveAway(BreedDog dog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Give Away'),
        content: Text('Are you sure you want to give away ${dog.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (dog.id != null) {
                await _deleteDog(dog.id!);
                widget.onGiveAway(dog);
              }
            },
            child: Text('Give Away', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Dog'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter dog name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a name')),
                );
                return;
              }

              final newDog = BreedDog(
                name: name,
                breed: Breed(name: 'Mixed Breed'),
                image: fetchRandomAnimalFromBreed('dog'),
              );
              
              await _addDog(newDog);
              _nameController.clear();
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Theme.of(context).colorScheme.secondary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _adoptedDogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No dogs adopted yet!',
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                ],
              ),
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              padding: EdgeInsets.all(16),
              itemCount: _adoptedDogs.length,
              itemBuilder: (context, index) {
                final dog = _adoptedDogs[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 150,
                        child: FutureBuilder<BreedImage>(
                          future: dog.image,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            } else if (snapshot.hasData) {
                              return ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: Image.network(snapshot.data!.imageUrl),
                                ),
                              );
                            }
                            return Center(child: Icon(Icons.error));
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEditing && _editingDog?.id == dog.id)
                              TextField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else
                              Text(
                                dog.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            SizedBox(height: 4),
                            Text(
                              dog.breed.name,
                              style: TextStyle(fontSize: 14),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (_isEditing && _editingDog?.id == dog.id)
                                  IconButton(
                                    icon: Icon(Icons.check, color: Colors.green),
                                    onPressed: _handleEditComplete,
                                  )
                                else
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _startEditing(dog),
                                  ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _handleDelete(dog),
                                ),
                                IconButton(
                                  icon: Icon(Icons.handshake, color: Colors.green),
                                  onPressed: () => _handleGiveAway(dog),
                                ),
                              ],
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

class BreedDog {
  int? id;
  String name;
  final Breed breed;
  final Future<BreedImage> image;
  DateTime adoptedDate;

  BreedDog({
    this.id,
    required this.name,
    required this.breed,
    required this.image,
    DateTime? adoptedDate,
  }) : adoptedDate = adoptedDate ?? DateTime.now();

  Future<Map<String, dynamic>> toMap() async {
    final imageUrl = await (await image).imageUrl;
    return {
      'id': id,
      'name': name,
      'breed': breed.name,
      'imageUrl': imageUrl,
      'adoptedDate': adoptedDate.toIso8601String(),
    };
  }

  factory BreedDog.fromMap(Map<String, dynamic> map) {
    return BreedDog(
      id: map['id'],
      name: map['name'],
      breed: Breed(name: map['breed']),
      image: Future.value(BreedImage(imageUrl: map['imageUrl'])),
      adoptedDate: DateTime.parse(map['adoptedDate']),
    );
  }
}

class Breed {
  final String name;
  Breed({required this.name});

  factory Breed.fromJson(String name) {
    return Breed(name: name);
  }
}

class BreedImage {
  final String imageUrl;

  BreedImage({required this.imageUrl});

  factory BreedImage.fromJson(Map<String, dynamic> json) {
    return BreedImage(imageUrl: json['message']);
  }
}

Future<List<Breed>> fetchBreeds() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Breed> breeds = List.from(data['message'].keys.map((name) => Breed.fromJson(name)));
    return breeds;
  } else {
    throw Exception('Failed to fetch breeds');
  }
}

Future<BreedImage> fetchRandomAnimalFromBreed(String breed) async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return BreedImage.fromJson(data);
  } else {
    throw Exception('Failed to fetch image from breed');
  }
}