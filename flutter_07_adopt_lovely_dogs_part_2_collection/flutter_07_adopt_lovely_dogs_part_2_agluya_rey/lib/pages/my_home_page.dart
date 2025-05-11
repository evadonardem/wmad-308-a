import 'package:flutter/material.dart';
import '../models/dog.dart';
import '../services/dog_service.dart';
import '../database/database_helper.dart';
import 'liked_dogs_page.dart';
import 'given_dogs_page.dart';
import 'about_page.dart';
import 'widgets/home_left_section.dart';
import 'widgets/home_right_section.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  late Future<List<Dog>> futureDogs;
  Future<Dog>? futureSelectedDog;
  bool hasSelection = false;
  bool isLoadingImage = false;
  Dog? selectedDog;
  List<Dog> filteredDogs = [];
  TextEditingController searchController = TextEditingController();
  bool showDropdown = false;
  List<Dog> likedDogs = [];
  List<Dog> givenDogs = [];
  int _selectedIndex = 0;
  final Map<int, TextEditingController> _nameControllers =
      {}; // Store controllers
  final Map<int, bool> _isNameChanged = {}; // Track name changes
  bool hoveredHeart = false; // Track hover state for heart button
  bool hoveredNext = false; // Track hover state for next button

  @override
  void initState() {
    super.initState();
    futureDogs = fetchDogs();
    futureDogs.then((dogs) {
      setState(() {
        filteredDogs = dogs;
      });
    });
    fetchAdoptedDogs();
    fetchGivenDogs(); // Fetch given dogs from the database
  }

  @override
  void dispose() {
    // Use a for loop instead of forEach
    for (var controller in _nameControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void handleDogSelection(Dog dog) {
    setState(() {
      hasSelection = true;
      isLoadingImage = true;
      futureSelectedDog = fetchRandomDogImage(dog.breed).then((dog) {
        setState(() {
          isLoadingImage = false;
          selectedDog = dog;
        });
        return dog;
      });
      showDropdown = false;
      searchController.text = dog.breed.toUpperCase();
    });
  }

  void filterDogs(String query) {
    futureDogs.then((dogs) {
      setState(() {
        filteredDogs = dogs
            .where(
                (dog) => dog.breed.toLowerCase().contains(query.toLowerCase()))
            .toList();
        showDropdown = true;
      });
    });
  }

  void likeDog(Dog dog) async {
    final id =
        await dbHelper.insertDog(dog); // Insert dog and get the generated id
    final newDog = Dog(
      id: id,
      breed: dog.breed,
      name: dog.name,
      imageUrl: dog.imageUrl,
    );

    setState(() {
      likedDogs.add(newDog); // Add the dog with the assigned id
    });
  }

  Future<void> fetchAdoptedDogs() async {
    final dogs = await dbHelper.getAdoptedDogs();
    setState(() {
      likedDogs = dogs;

      // Reinitialize controllers and state for the updated likedDogs list
      _nameControllers.clear();
      _isNameChanged.clear();
      for (var dog in likedDogs) {
        _nameControllers[dog.id!] = TextEditingController(text: dog.name);
        _isNameChanged[dog.id!] = false;
      }
    });
  }

  void updateDogName(int? id, String newName) async {
    if (id != null) {
      await dbHelper.updateDogName(id, newName); // Ensure id is non-null
      fetchAdoptedDogs();
    }
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

  void giveDog(Dog dog) async {
    if (dog.id != null) {
      // Remove the dog from the adopted_dogs table
      await dbHelper.deleteDog(dog.id!);

      // Add the dog to the given_dogs table
      await dbHelper.insertGivenDog(dog);

      setState(() {
        // Remove the dog from the likedDogs list
        likedDogs.removeWhere((likedDog) => likedDog.id == dog.id);

        // Clear the controller and state for the removed dog
        _nameControllers[dog.id!]?.dispose();
        _nameControllers.remove(dog.id!);
        _isNameChanged.remove(dog.id!);

        // Add the dog to the givenDogs list
        givenDogs.add(dog);
      });
    }
  }

  Future<void> fetchGivenDogs() async {
    final dogs = await dbHelper.getGivenDogs();
    setState(() {
      givenDogs = dogs;
    });
  }

  void deleteDogPermanently(int id) async {
    await dbHelper.deleteDog(id);
    fetchAdoptedDogs();
  }

  void deleteDogFromGiven(int id) async {
    await dbHelper.deleteDogFromGiven(id); // Remove the dog from the database
    fetchGivenDogs(); // Refresh the given dogs list
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages() {
    return [
      // Page 1: Home Page
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0), // Adjust padding
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // Align content to the top
              children: [
                Expanded(
                  flex: 1,
                  child: HomeLeftSection(
                    hasSelection: hasSelection,
                    isLoadingImage: isLoadingImage,
                    futureSelectedDog: futureSelectedDog,
                    selectedDog: selectedDog,
                    likeDog: likeDog,
                    fetchNextDog: fetchNextDog,
                  ),
                ),
                SizedBox(width: 20), // Add spacing between sections
                Expanded(
                  flex: 2,
                  child: HomeRightSection(
                    searchController: searchController,
                    filteredDogs: filteredDogs,
                    handleDogSelection: handleDogSelection,
                    filterDogs: filterDogs,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // Page 2: Liked Dogs Page
      LikedDogsPage(
        likedDogs: likedDogs,
        nameControllers: _nameControllers,
        isNameChanged: _isNameChanged,
        giveDog: giveDog,
        updateDogName: updateDogName,
      ),
      // Page 3: Given Dogs Page
      GivenDogsPage(
        givenDogs: givenDogs,
        deleteDogFromGiven: deleteDogFromGiven,
      ),

      // Page 4: About Me Page
      const AboutPage(), // Use the new AboutPage widget
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPages().elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Liked Dogs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Given Dogs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'About Me'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFEDF2F4),
        unselectedItemColor: Color(0xFF8D99AE),
        backgroundColor: Color(0xFF2B2D42),
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
