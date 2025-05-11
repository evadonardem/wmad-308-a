import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart' show WordPair;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'notification_widget.dart';
import 'package:synchronized/synchronized.dart'; 
import 'pages/about_page.dart';
import 'pages/adopted_dogs_page.dart';
import 'pages/give_away_page.dart';
import 'pages/home_page.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
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

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final _lock = Lock(); 

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await _initDB('dogs.db');
      return _database!;
    } catch (e) {
      developer.log('Error initializing database: $e', level: 1);  
      rethrow;
    }
  }

  Future<Database> _initDB(String fileName) async {
    try {
      final dbPath = join(Directory.current.path, '.dart_tool', 'sqflite_common_ffi');
      final directory = Directory(dbPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final path = join(dbPath, fileName);

      developer.log('Database path: $path'); 

      return await openDatabase(path, version: 1, onCreate: _createDB);
    } catch (e) {
      developer.log('Error creating database: $e', level: 1);
      rethrow;
    }
  }

  Future<String> getApplicationDocumentsDirectoryPath() async {
    final directory = Directory('${Directory.current.path}/databases');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  Future<void> _createDB(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE adopted_dogs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          breed TEXT(100) NOT NULL,
          imageUrl TEXT(255) NOT NULL,
          name TEXT(100) NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE give_away_dogs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          breed TEXT(100) NOT NULL,
          imageUrl TEXT(255) NOT NULL,
          name TEXT(100) NOT NULL
        )
      ''');
    } catch (e) {
      developer.log('Error creating tables: $e', level: 1); 
    }
  }

  Future<void> insertAdoptedDog(AdoptedDog dog) async {
    await _lock.synchronized(() async {
      final db = await instance.database;
      final id = await db.insert('adopted_dogs', {
        'breed': dog.breed,
        'imageUrl': dog.imageUrl,
        'name': dog.name,
      });
      developer.log('Inserted adopted dog: ${dog.name}, ID: $id'); 
    });
  }

  Future<void> insertGiveAwayDog(GiveAwayDog dog) async {
    await _lock.synchronized(() async {
      final db = await instance.database;
      final id = await db.insert('give_away_dogs', {
        'breed': dog.breed,
        'imageUrl': dog.imageUrl,
        'name': dog.name,
      });
      developer.log('Inserted give away dog: ${dog.name}, ID: $id'); 
    });
  }

  Future<void> deleteAdoptedDog(String name) async {
    await _lock.synchronized(() async { 
      final db = await instance.database;
      await db.delete('adopted_dogs', where: 'name = ?', whereArgs: [name]);
    });
  }

  Future<void> deleteGiveAwayDog(String name) async {
    await _lock.synchronized(() async { 
      final db = await instance.database;
      await db.delete('give_away_dogs', where: 'name = ?', whereArgs: [name]);
    });
  }

  Future<List<AdoptedDog>> fetchAdoptedDogs() async {
    try {
      final db = await database;
      final result = await db.query('adopted_dogs');
      developer.log('Fetched adopted dogs: $result'); 
      return result.map((json) => AdoptedDog(
        breed: json['breed'] as String,
        imageUrl: json['imageUrl'] as String,
        name: json['name'] as String,
      )).toList();
    } catch (e) {
      developer.log('Error fetching adopted dogs: $e', level: 1); 
      rethrow;
    }
  }

  Future<List<GiveAwayDog>> fetchGiveAwayDogs() async {
    try {
      final db = await database;
      final result = await db.query('give_away_dogs');
      developer.log('Fetched give away dogs: $result'); 
      return result.map((json) => GiveAwayDog(
        breed: json['breed'] as String,
        imageUrl: json['imageUrl'] as String,
        name: json['name'] as String,
      )).toList();
    } catch (e) {
      developer.log('Error fetching give away dogs: $e', level: 1); 
      rethrow;
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'Orbitron', 
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 0, 0)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF555555),
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
  int? _hoveredIndex;
  List<AdoptedDog> adoptedDogs = [];
  List<GiveAwayDog> giveAwayDogs = [];
  String? notificationMessage;

  final GlobalKey<MyHomePageState> homePageKey = GlobalKey<MyHomePageState>();
  final GlobalKey<AdoptedDogsPageState> adoptedDogsPageKey = GlobalKey<AdoptedDogsPageState>();
  final GlobalKey<GiveAwayPageState> giveAwayPageKey = GlobalKey<GiveAwayPageState>();

  @override
  void initState() {
    super.initState();
    _loadDogsFromDatabase();
  }

  Future<void> _loadDogsFromDatabase() async {
    final dbHelper = DatabaseHelper.instance;
    try {
      final adopted = await dbHelper.fetchAdoptedDogs();
      final giveAway = await dbHelper.fetchGiveAwayDogs();
      developer.log('Loaded adopted dogs from database: $adopted'); 
      developer.log('Loaded give away dogs from database: $giveAway'); 
      setState(() {
        adoptedDogs = adopted;
        giveAwayDogs = giveAway;
      });
    } catch (e) {
      developer.log('Error fetching data from database: $e', level: 1); 
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index || index == 0) {
      setState(() {
        if (index == 0 && homePageKey.currentState != null) {
          notificationMessage = null;
          homePageKey.currentState!.resetHomePage();
        } else if (index == 1 && adoptedDogsPageKey.currentState != null) {
          adoptedDogsPageKey.currentState!.resetAnimation();
        } else if (index == 2 && giveAwayPageKey.currentState != null) {
          giveAwayPageKey.currentState!.loadGiveAwayDogs();
          giveAwayPageKey.currentState!.resetAnimation();
        }
        _selectedIndex = index;
      });
    }
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

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: MouseRegion(
        onEnter: (_) => setState(() {
          if (_hoveredIndex != index) _hoveredIndex = index;
        }),
        onExit: (_) => setState(() {
          if (_hoveredIndex == index) _hoveredIndex = null;
        }),
        child: Container(
          decoration: BoxDecoration(
            color: _hoveredIndex == index ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20.0,
                color: _hoveredIndex == index ? Colors.black : Colors.white,
              ),
              const SizedBox(height: 2.0),
              Text(
                label,
                style: TextStyle(
                  color: _hoveredIndex == index ? Colors.black : Colors.white,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ),
      ),
      label: '',
    );
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
                  key: homePageKey,
                  title: 'Homebound Hounds',
                  adoptedDogs: adoptedDogs,
                  showNotification: _showNotification,
                ),
                AdoptedDogsPage(
                  key: adoptedDogsPageKey,
                  adoptedDogs: adoptedDogs,
                  giveAwayDogs: giveAwayDogs,
                  showNotification: _showNotification,
                ),
                GiveAwayPage(
                  key: giveAwayPageKey,
                  giveAwayDogs: giveAwayDogs,
                  showNotification: _showNotification,
                ),
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
        items: <BottomNavigationBarItem>[
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.pets, 'Adopted Dogs', 1),
          _buildNavItem(Icons.local_offer, 'Give Away', 2),
          _buildNavItem(Icons.info, 'About', 3),
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