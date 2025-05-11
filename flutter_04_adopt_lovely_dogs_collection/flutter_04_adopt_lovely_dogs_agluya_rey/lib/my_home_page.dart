import 'package:flutter/material.dart';
import 'dog.dart';
import 'dog_service.dart';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _buildPages() {
    return [
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 50.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Select a Dog",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
                            width: 300,
                            child: Stack(
                              children: [
                                TextField(
                                  controller: searchController,
                                  cursorWidth: 3.0, // Increase cursor width
                                  cursorColor: Colors.yellow, // Change cursor color
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
                              width: 300,
                              constraints: BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredDogs.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(filteredDogs[index].breed.toUpperCase(), style: TextStyle(color: Colors.white)),
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
                          padding: const EdgeInsets.only(top: 20.0),
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
                                      height: 200,
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
                                          backgroundColor: Color(0xFF8D99AE),
                                          shadowColor: Colors.white,
                                          elevation: 0,
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
                                          "Like",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: fetchNextDog,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF8D99AE),
                                          shadowColor: Colors.white,
                                          elevation: 0,
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
          width: 350,
          child: ListView.builder(
            itemCount: likedDogs.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF8D99AE),
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
                      backgroundColor: Color(0xFF8D99AE),
                      shadowColor: Colors.white,
                      elevation: 0,
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
          width: 350,
          child: ListView.builder(
            itemCount: givenDogs.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color(0xFF8D99AE),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'About Me',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Dogos Match is a user-friendly pet adoption app designed to connect loving families with pets in need of a home. Whether you’re looking for a playful puppy, a loyal dog, a cuddly kitten, or a gentle cat, our app helps you find the perfect companion with just a few taps.' ,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
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
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Liked Dogs'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Given Dogs'),
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