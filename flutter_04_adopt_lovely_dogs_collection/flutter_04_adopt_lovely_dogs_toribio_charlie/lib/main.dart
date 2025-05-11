import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dog',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: Color(0xFF3674B5), // HEX: #b2c2bf
          primaryContainer: Color(0xFFA1E3F9), // HEX: #c0ded9
          secondary: Color(0xFF578FCA), // HEX: #eaece5
          secondaryContainer: Color(0xFFD1F8EF), // HEX: #3b3a30
          surface: Color(0xFF493D9E), // HEX: #3b3a30
          error: Color(0xFF00879E), // Red for errors
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  @override
  void initState() {
    super.initState();
    futureDogs = fetchDogs();
    futureDogs.then((dogs) {
      setState(() {
        filteredDogs = dogs;
      });
    });
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

  void likeDog(Dog dog) {
    setState(() {
      if (!likedDogs.any((likedDog) =>
          likedDog.imageUrl == dog.imageUrl && likedDog.name == dog.name)) {
        likedDogs.add(dog);
      }
    });
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

  void giveDog(Dog dog) {
    setState(() {
      likedDogs.remove(dog);
      givenDogs.add(dog);
    });
  }

  void deleteGivenDog(Dog dog) {
    setState(() {
      givenDogs.remove(dog);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages() {
    return [
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0), // Adjust the top padding here
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Select a Dog",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                FutureBuilder<List<Dog>>(
                  future: futureDogs,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(
                        color: Color(0xFF8D99AE),
                      );
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Column(
                        children: [
                          SizedBox(
                            width: 300, // Set the width of the TextField
                            child: Stack(
                              children: [
                                TextField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    hintText: "Type to search...",
                                    hintStyle: TextStyle(color: Colors.white),
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                      onPressed: () {
                                        setState(() {
                                          showDropdown = !showDropdown;
                                        });
                                      },
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  onChanged: (value) {
                                    filterDogs(value);
                                  },
                                ),
                              ],
                            ),
                          ),
                          if (showDropdown)
                            Container(
                              width: 300, // Match the width of the TextField
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredDogs.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(filteredDogs[index]
                                        .breed
                                        .toUpperCase(), style: TextStyle(color: Colors.white)),
                                    onTap: () {
                                      handleDogSelection(filteredDogs[index]);
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    }
                    return const Text("No dogs found.", style: TextStyle(color: Colors.white));
                  },
                ),
                if (hasSelection)
                  isLoadingImage
                      ? Padding(
                          padding: const EdgeInsets.only(
                              top: 20.0), // Adjust the position to be lower
                          child: const CircularProgressIndicator(
                            color: Color(0xFF8D99AE),
                          ),
                        )
                      : FutureBuilder<Dog>(
                          future: futureSelectedDog,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.network(
                                      snapshot.data!.imageUrl,
                                      width: 250, // Increased width
                                      height: 250, // Increased height
                                      fit: BoxFit.cover, // Ensure the image covers the box
                                    ),
                                  ),
                                  Text(
                                    snapshot.data!.name.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          likeDog(snapshot.data!);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF8D99AE), // Button color
                                          shadowColor: Colors.white,
                                          elevation: 0, // No shadow by default
                                          textStyle: TextStyle(color: Colors.white),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ).copyWith(
                                          elevation: WidgetStateProperty.resolveWith<double>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return 10;
                                              }
                                              return 0;
                                            },
                                          ),
                                          shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                );
                                              }
                                              return RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              );
                                            },
                                          ),
                                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return Color(0xFFB0BEC5);
                                              }
                                              return Color(0xFF8D99AE);
                                            },
                                          ),
                                          overlayColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                // ignore: deprecated_member_use
                                                return Colors.white.withOpacity(0.1);
                                              }
                                              return Colors.transparent;
                                            },
                                          ),
                                        ),
                                        child: const Text(
                                          "Adopt",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: fetchNextDog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF8D99AE), // Button color
                                          shadowColor: Colors.white,
                                          elevation: 0, // No shadow by default
                                          textStyle: TextStyle(color: Colors.white),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ).copyWith(
                                          elevation: WidgetStateProperty.resolveWith<double>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return 10;
                                              }
                                              return 0;
                                            },
                                          ),
                                          shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                );
                                              }
                                              return RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              );
                                            },
                                          ),
                                          backgroundColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                return Color(0xFFB0BEC5);
                                              }
                                              return Color(0xFF8D99AE);
                                            },
                                          ),
                                          overlayColor: WidgetStateProperty.resolveWith<Color>(
                                            (Set<WidgetState> states) {
                                              if (states.contains(WidgetState.hovered)) {
                                                // ignore: deprecated_member_use
                                                return Colors.white.withOpacity(0.1);
                                              }
                                              return Colors.transparent;
                                            },
                                          ),
                                        ),
                                        child: const Text(
                                          "Next",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                            return const SizedBox();
                          }),
              ],
            ),
          ),
        ),
      ),
      Center(
        child: SizedBox(
          width: 350, // Adjust the width to center the list
          child: ListView.builder(
            itemCount: likedDogs.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF8D99AE), // Border color
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Image.network(
                    likedDogs[index].imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(likedDogs[index].breed, style: TextStyle(color: Colors.white)),
                  subtitle: Text(likedDogs[index].name, style: TextStyle(color: Colors.white)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      giveDog(likedDogs[index]);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8D99AE), // Button color
                      shadowColor: Colors.white,
                      elevation: 0, // No shadow by default
                      textStyle: TextStyle(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith<double>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return 10;
                          }
                          return 0;
                        },
                      ),
                      shape: WidgetStateProperty.resolveWith<OutlinedBorder>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            );
                          }
                          return RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          );
                        },
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            return Color(0xFFB0BEC5);
                          }
                          return Color(0xFF8D99AE);
                        },
                      ),
                      overlayColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.hovered)) {
                            // ignore: deprecated_member_use
                            return Colors.white.withOpacity(0.1);
                          }
                          return Colors.transparent;
                        },
                      ),
                    ),
                    child: const Text(
                      "Give",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Center(
        child: SizedBox(
          width: 350, // Adjust the width to center the list
          child: ListView.builder(
            itemCount: givenDogs.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF8D99AE), // Border color
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Image.network(
                    givenDogs[index].imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(givenDogs[index].breed, style: TextStyle(color: Colors.white)),
                  subtitle: Text(givenDogs[index].name, style: TextStyle(color: Colors.white)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.white),
                    onPressed: () {
                      deleteGivenDog(givenDogs[index]);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://example.com/your-profile-picture.jpg'), // Replace with your profile picture URL
              ),
              SizedBox(height: 16),
              Text(
                'Charlie Toribio',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Dog Lover & Rescuer',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              SizedBox(height: 16),
              Card(
                color: Color(0xFF3b3a30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
'Hello! I am Charlie Toribio, a dedicated dog lover and rescuer. My mission is to provide a loving home for every dog in need. This platform is a place where you can find your new furry friend, learn about responsible pet ownership, and support the cause of rescuing dogs. Let\'s make a difference together, one paw at a time! 🐾❤️',
style: TextStyle(fontSize: 16, color: Colors.white),
textAlign: TextAlign.left,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Add your contact action here
                },
                icon: Icon(Icons.email, color: Colors.white),
                label: Text('Contact Me', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8D99AE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              icon: Icon(Icons.favorite), label: 'Adopted '),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Give Away Dogs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'About'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Color(0xFFEDF2F4), // Color for the selected item
        unselectedItemColor: Color(0xFF8D99AE),
        backgroundColor: Color(0xFF2B2D42),
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}

class Dog {
  final String breed;
  final String name;
  final String imageUrl;

  Dog({required this.breed, required this.name, required this.imageUrl});

  factory Dog.withRandomName(String breed, String imageUrl) {
    return Dog(
        breed: breed, name: WordPair.random().join(""), imageUrl: imageUrl);
  }
}

Future<List<Dog>> fetchDogs() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Dog> dogs = [];
    for (var breed in data['message'].keys) {
      dogs.add(Dog(breed: breed, name: WordPair.random().join(), imageUrl: ''));
    }
    return dogs;
  } else {
    throw Exception('Failed to fetch dogs');
  }
}

Future<String> fetchRandomDogImageUrl(String breed) async {
  final dogImageEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('Failed to fetch image for breed');
  }
}

Future<Dog> fetchRandomDogImage(String breed) async {
  final imageUrl = await fetchRandomDogImageUrl(breed);
  return Dog.withRandomName(breed, imageUrl);
}