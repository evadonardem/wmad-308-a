import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;
import 'dart:async';

void main() {
  sqfliteFfiInit();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DogAdoptionApp());
}

class Dog {
  final String imageUrl;
  final String status;

  Dog({required this.imageUrl, required this.status});

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  factory Dog.fromMap(Map<String, dynamic> map) {
    return Dog(
      imageUrl: map['imageUrl'],
      status: map['status'],
    );
  }
}

class DatabaseHelper {
  static Future<Database> _initializeDB() async {
    final dbPath = await getDatabasesPath();
    final dbFilePath = path.join(dbPath, 'dogs.db');

    return openDatabase(
      dbFilePath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE dogs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imageUrl TEXT,
            status TEXT
          )
        ''');
      },
    );
  }

  static Future<void> insertDog(Dog dog) async {
    final db = await _initializeDB();
    await db.insert(
      'dogs',
      dog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Dog>> fetchDogs() async {
    final db = await _initializeDB();
    final List<Map<String, dynamic>> maps = await db.query('dogs');
    return List.generate(maps.length, (i) => Dog.fromMap(maps[i]));
  }
}

class DogAdoptionApp extends StatefulWidget {
  @override
  _DogAdoptionAppState createState() => _DogAdoptionAppState();
}

class _DogAdoptionAppState extends State<DogAdoptionApp> {
  int _selectedIndex = 0;
  String? selectedBreed;
  String? _latestActionStatus;

  void _onBreedSelected(String breed) {
    setState(() {
      selectedBreed = breed;
      _selectedIndex = 0;
    });
  }

  void _onAdopt(String dogUrl) async {
    await DatabaseHelper.insertDog(Dog(imageUrl: dogUrl, status: 'adopted'));
    setState(() {
      _latestActionStatus = 'adopted';
    });
  }

  void _onDislike(String dogUrl) async {
    await DatabaseHelper.insertDog(Dog(imageUrl: dogUrl, status: 'disliked'));
    setState(() {
      _latestActionStatus = 'disliked';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DogAdoptionScreen(
        selectedBreed: () => selectedBreed,
        onAdopt: _onAdopt,
        onDislike: _onDislike,
      ),
      BreedsScreen(onBreedSelect: _onBreedSelected),
      HistoryScreen(latestStatus: _latestActionStatus),
    ];

    return MaterialApp(
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopt'),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Breeds'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history), label: 'History'),
          ],
        ),
      ),
    );
  }
}

class BreedsScreen extends StatefulWidget {
  final Function(String) onBreedSelect;

  BreedsScreen({required this.onBreedSelect});

  @override
  _BreedsScreenState createState() => _BreedsScreenState();
}

class _BreedsScreenState extends State<BreedsScreen> {
  List<String> breeds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBreeds();
  }

  Future<void> fetchBreeds() async {
    try {
      final response =
          await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['message'];
        final List<String> loadedBreeds = [];
        data.forEach((breed, subBreeds) {
          if ((subBreeds as List).isEmpty) {
            loadedBreeds.add(breed);
          } else {
            for (String sub in subBreeds) {
              loadedBreeds.add('$breed $sub');
            }
          }
        });
        setState(() {
          breeds = loadedBreeds..sort();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load breeds');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select a Breed')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: breeds.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(breeds[index]),
                  onTap: () => widget.onBreedSelect(breeds[index]),
                );
              },
            ),
    );
  }
}

class DogAdoptionScreen extends StatefulWidget {
  final String? Function() selectedBreed;
  final Function(String) onAdopt;
  final Function(String) onDislike;

  DogAdoptionScreen({
    required this.selectedBreed,
    required this.onAdopt,
    required this.onDislike,
  });

  @override
  _DogAdoptionScreenState createState() => _DogAdoptionScreenState();
}

class _DogAdoptionScreenState extends State<DogAdoptionScreen> {
  String? dogImageUrl;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchNewDog());
  }

  Future<void> fetchNewDog() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      dogImageUrl = null;
    });

    try {
      final breed = widget.selectedBreed();
      final breedQuery = (breed != null && breed.isNotEmpty)
          ? breed.toLowerCase().replaceAll(' ', '/')
          : '';
      final url = breedQuery.isNotEmpty
          ? 'https://dog.ceo/api/breed/$breedQuery/images/random'
          : 'https://dog.ceo/api/breeds/image/random';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          dogImageUrl = json.decode(response.body)['message'];
        });
      } else {
        throw Exception('Failed to load dog image');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading dog image. Please try again later.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void adoptDog() {
    if (dogImageUrl != null) {
      widget.onAdopt(dogImageUrl!);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CertificateScreen(
            dogImageUrl: dogImageUrl!,
            onAdoptAgain: fetchNewDog,
          ),
        ),
      );
    }
  }

  void dislikeDog() {
    if (dogImageUrl != null) {
      widget.onDislike(dogImageUrl!);
    }
    fetchNewDog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dog Adoption')),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : errorMessage != null
                ? Text(errorMessage!, style: TextStyle(color: Colors.red))
                : dogImageUrl != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.network(dogImageUrl!,
                              height: 300, fit: BoxFit.cover),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                  onPressed: adoptDog, child: Text('Adopt ❤️')),
                              ElevatedButton(
                                  onPressed: dislikeDog,
                                  child: Text('Dislike ❌')),
                            ],
                          ),
                        ],
                      )
                    : Container(),
      ),
    );
  }
}

class CertificateScreen extends StatelessWidget {
  final String dogImageUrl;
  final VoidCallback onAdoptAgain;

  const CertificateScreen({
    required this.dogImageUrl,
    required this.onAdoptAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adoption Certificate')),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 3),
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade400,
                blurRadius: 10,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Certificate of Adoption',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Image.network(dogImageUrl, height: 200),
              SizedBox(height: 20),
              Text('Congratulations!', style: TextStyle(fontSize: 20)),
              Text('You adopted this lovely pup 🐶',
                  style: TextStyle(fontSize: 18)),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAdoptAgain();
                },
                child: Text('Adopt Again'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final String? latestStatus;

  const HistoryScreen({this.latestStatus});

  Future<List<Dog>> _fetchHistory() async {
    return await DatabaseHelper.fetchDogs();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (latestStatus != null) {
        final message = latestStatus == 'adopted'
            ? 'Dog successfully adopted!'
            : 'Dog marked as disliked.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: Duration(seconds: 2)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text('Adoption History')),
      body: FutureBuilder<List<Dog>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error fetching history: ${snapshot.error}'),
            );
          }

          final dogs = snapshot.data;

          if (dogs == null || dogs.isEmpty) {
            return Center(child: Text('No dogs adopted or disliked yet.'));
          }

          return ListView.builder(
            itemCount: dogs.length,
            itemBuilder: (context, index) {
              final dog = dogs[index];
              return ListTile(
                leading: Image.network(
                  dog.imageUrl,
                  height: 50,
                  width: 50,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported),
                ),
                title: Text(
                    dog.status == 'adopted' ? 'Adopted Dog' : 'Disliked Dog'),
              );
            },
          );
        },
      ),
    );
  }
}
