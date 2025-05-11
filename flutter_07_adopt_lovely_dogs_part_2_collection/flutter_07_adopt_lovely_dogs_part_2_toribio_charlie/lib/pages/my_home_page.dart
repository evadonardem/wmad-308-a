import 'package:flutter/material.dart';
import '../models/dog.dart';
import '../services/dog_service.dart';
import '../database/database_helper.dart';
import 'liked_dogs_page.dart';
import 'given_dogs_page.dart';
import 'about_page.dart';

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

  late Future<List<String>> futureDogBreeds;
  String? selectedBreed;
  String? dogImageUrl;
  String dogName = "Unknown";
  bool isLoading = false;

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
    futureDogBreeds = fetchDogBreeds(); // Fetch the list of dog breeds
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

  Future<void> updateDogImage(String breed) async {
    setState(() {
      isLoading = true;
    });
    final dog = await fetchRandomDogImage(breed);
    setState(() {
      dogImageUrl = dog.imageUrl;
      dogName = dog.name;
      isLoading = false;
    });
  }

  void adoptDog() {
    if (dogImageUrl != null && selectedBreed != null) {
      final newDog = Dog(
        breed: selectedBreed!,
        name: dogName,
        imageUrl: dogImageUrl!,
      );
      likeDog(newDog);
    }
  }

  List<Widget> _buildPages() {
    return [
      // Page 1: Home Page
      Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FutureBuilder<List<String>>(
              future: futureDogBreeds,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No breeds found');
                }
                return DropdownButtonFormField<String>(
                  value: selectedBreed,
                  hint: const Text('🐕 Select a Breed'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ),
                  dropdownColor: Colors.white, // Set dropdown background color
                  style: const TextStyle(color: Colors.black), // Set text color
                  items: snapshot.data!.map((breed) {
                    return DropdownMenuItem(
                      value: breed,
                      child: Text(breed, style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedBreed = newValue;
                    });
                    if (newValue != null) {
                      updateDogImage(newValue);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const CircularProgressIndicator()
            else if (dogImageUrl != null)
              Column(
                children: [
                  Image.network(
                    dogImageUrl!,
                    width: 350,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "🐾 Name: $dogName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: adoptDog,
                        child: const Text("Adopt 🐶"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (selectedBreed != null) {
                            updateDogImage(selectedBreed!);
                          }
                        },
                        child: const Text("Explore More 🔄"),
                      ),
                    ],
                  ),
                ],
              )
            else
              const Text(
                "🐾 Select a breed to see its image",
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
              ),
          ],
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
        selectedItemColor: Color.fromARGB(255, 107, 189, 222),
        unselectedItemColor: Color(0xFF8D99AE),
        backgroundColor: Color(0xFF2B2D42),
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}
