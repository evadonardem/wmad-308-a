import 'package:flutter/material.dart';
import 'package:flutter_03_lovely_dogs_marafo_melbert/screens/about_page.dart';
import 'package:flutter_03_lovely_dogs_marafo_melbert/screens/give_away_page.dart';
import 'models.dart';
import 'screens/home_page.dart';
import 'screens/adopted_dogs_page.dart';
import 'utils.dart';
import 'widgets/navigation_bar_widget.dart';

void main() {
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
  List<Dog> adoptedDogs = [];  
  List<Dog> dogs = [];        
  List<Dog> giveAwayDogs = []; 

  @override
  void initState() {
    super.initState();
    _loadDogs(); 
  }

  Future<void> _loadDogs() async {
    if (dogs.isNotEmpty) return;

    try {
      List<Dog> fetchedDogs = await fetchDogs();
      if (mounted) {
        setState(() {
          dogs = fetchedDogs;
        });
      }
    } catch (e) {
      debugPrint("Error loading dogs: $e");
    }
  }

  void _adoptDog(Dog dog) {
    setState(() {
      if (!adoptedDogs.contains(dog)) {
        adoptedDogs.add(dog);
      }
    });
  }

  void _giveAwayDog(Dog dog) {
    setState(() {
      adoptedDogs.remove(dog);
      giveAwayDogs.add(dog);
    });
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
      GiveAwayPage(giveAwayDogs: giveAwayDogs),
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
