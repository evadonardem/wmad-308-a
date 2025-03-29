import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'screens/about_page.dart';
import 'screens/give_away_page.dart';
import 'models.dart';
import 'screens/home_page.dart';
import 'screens/adopted_dogs_page.dart';
import 'utils.dart';
import 'widgets/navigation_bar_widget.dart';
import 'database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dog Adopt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late DogDatabase db;
  List<Dog> adoptedDogs = [];
  List<Dog> dogs = [];
  List<Dog> giveAwayDogs = [];

  @override
  void initState() {
    super.initState();
    db = DogDatabase.instance;
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    try {
      List<Dog> localDogs = await db.getAllDogs();
      List<Dog> localAdoptedDogs = await db.getAdoptedDogs();
      List<Dog> localGiveAwayDogs = await db.getGiveAwayDogs();

      if (mounted) {
        setState(() {
          dogs = localDogs;
          adoptedDogs = localAdoptedDogs;
          giveAwayDogs = localGiveAwayDogs;
        });
      }

      if (localDogs.isEmpty) {
        List<Dog> fetchedDogs = await fetchDogs();
        await Future.wait(fetchedDogs.map((dog) => db.addDog(Dog(name: WordPair.random().asPascalCase, breed: dog.breed, imageUrl: dog.imageUrl, id: dog.id), 'dogs')));

        if (mounted) {
          setState(() {
            dogs = fetchedDogs;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading dogs: $e');
    }
  }

  void _adoptDog(Dog dog) async {
    try {
      await db.adoptDog(dog);
      setState(() {
        dogs.remove(dog);
        if (!adoptedDogs.contains(dog)) {
          adoptedDogs.add(dog);
        }
      });
    } catch (e) {
      debugPrint('Error adopting dog: $e');
    }
  }

  void _giveAwayDog(Dog dog) async {
    try {
      await db.giveAwayDog(dog);
      setState(() {
        adoptedDogs.remove(dog);
        giveAwayDogs.add(dog);
      });
    } catch (e) {
      debugPrint('Error giving away dog: $e');
    }
  }

  void _removeGiveAway(Dog dog) async {
    try {
      await db.removeGiveAwayDog(dog);
      setState(() {
        giveAwayDogs.remove(dog);
      });
    } catch (e) {
      debugPrint('Error removing giveaway dog: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(onAdopt: _adoptDog, dogs: dogs),
      AdoptedDogsPage(adoptedDogs: adoptedDogs, onGiveAway: _giveAwayDog),
      GiveAwayPage(giveAwayDogs: giveAwayDogs, onRemoveGiveAway: _removeGiveAway),
      AboutPage(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBarWidget(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}