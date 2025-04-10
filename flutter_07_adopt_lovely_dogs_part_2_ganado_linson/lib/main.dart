import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey, 
      theme: ThemeData(
        colorScheme: const ColorScheme(
          primary: Color(0xFFb2c2bf), 
          primaryContainer: Color(0xFFc0ded9), 
          secondary: Color(0xFFeaece5), 
          secondaryContainer: Color(0xFF3b3a30), 
          surface: Color(0xFF3b3a30), 
          background: Color(0xFFeaece5), 
          error: Color(0xFFD32F2F), 
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onBackground: Colors.black,
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
  late Database database;

  @override
  void initState() {
    super.initState();
    initializeDatabase();
    futureDogs = fetchDogs();
    futureDogs.then((dogs) {
      setState(() {
        filteredDogs = dogs;
      });
    });
  }

  Future<void> initializeDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'dogs_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE adopted_dogs(id INTEGER PRIMARY KEY, breed TEXT, name TEXT, imageUrl TEXT);',
        );
      },
      version: 1,
    );
    await database.execute(
      'CREATE TABLE IF NOT EXISTS given_dogs(id INTEGER PRIMARY KEY, breed TEXT, name TEXT, imageUrl TEXT);',
    );
    loadDogsFromDatabase();
  }

  Future<void> loadDogsFromDatabase() async {
    final List<Map<String, dynamic>> adoptedDogsData =
        await database.query('adopted_dogs');
    final List<Map<String, dynamic>> givenDogsData =
        await database.query('given_dogs');

    setState(() {
      likedDogs = adoptedDogsData
          .map((dog) => Dog(
                breed: dog['breed'],
                name: dog['name'],
                imageUrl: dog['imageUrl'],
              ))
          .toList();
      givenDogs = givenDogsData
          .map((dog) => Dog(
                breed: dog['breed'],
                name: dog['name'],
                imageUrl: dog['imageUrl'],
              ))
          .toList();
    });
  }

  Future<void> saveAdoptedDog(Dog dog) async {
    await database.insert(
      'adopted_dogs',
      {'breed': dog.breed, 'name': dog.name, 'imageUrl': dog.imageUrl},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveGivenDog(Dog dog) async {
    await database.insert(
      'given_dogs',
      {'breed': dog.breed, 'name': dog.name, 'imageUrl': dog.imageUrl},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteGivenDogFromDatabase(Dog dog) async {
    await database.delete(
      'given_dogs',
      where: 'breed = ? AND name = ? AND imageUrl = ?',
      whereArgs: [dog.breed, dog.name, dog.imageUrl],
    );
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
    if (likedDogs.any((likedDog) =>
        likedDog.imageUrl == dog.imageUrl && likedDog.name == dog.name)) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '${dog.name} has already been adopted!',
            style: TextStyle(fontSize: 18), 
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      likedDogs.add(dog);
    });
    await saveAdoptedDog(dog);
    await loadDogsFromDatabase(); 

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          '${dog.name} has been adopted!',
          style: TextStyle(fontSize: 18), 
        ),
        backgroundColor: Colors.green,
      ),
    );
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
    setState(() {
      likedDogs = likedDogs.where((likedDog) => likedDog != dog).toList(); 
    });
    await saveGivenDog(dog); 
    await database.delete( 
      'adopted_dogs',
      where: 'breed = ? AND name = ? AND imageUrl = ?',
      whereArgs: [dog.breed, dog.name, dog.imageUrl],
    );

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          '${dog.name} has been given away!',
          style: TextStyle(fontSize: 18), 
        ),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void deleteGivenDog(Dog dog) async {
    setState(() {
      givenDogs.remove(dog); 
    });
    await deleteGivenDogFromDatabase(dog);
    await loadDogsFromDatabase(); 

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          '${dog.name} has been removed from the given list!',
          style: TextStyle(fontSize: 18), 
        ),
        backgroundColor: Colors.orange,
      ),
    );
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
                            width: 300, 
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
                              width: 300, 
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
                              top: 20.0), 
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
                                      width: 250, 
                                      height: 250, 
                                      fit: BoxFit.cover, 
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
                                          backgroundColor: const Color(0xFF8D99AE), 
                                          shadowColor: Colors.white,
                                          elevation: 0, 
                                          textStyle: const TextStyle(color: Colors.white),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
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
                                          backgroundColor: const Color(0xFF8D99AE), 
                                          shadowColor: Colors.white,
                                          elevation: 0, 
                                          textStyle: const TextStyle(color: Colors.white),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, 
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65, 
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          likedDogs[index].imageUrl,
                          fit: BoxFit.fill, 
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          Text(
                            "Name: ${likedDogs[index].name}",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Breed: ${likedDogs[index].breed}",
                            style: TextStyle(fontSize: 10, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        giveDog(likedDogs[index]);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8D99AE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Give Away",
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, 
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.65,
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          givenDogs[index].imageUrl,
                          fit: BoxFit.fill, 
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: [
                          Text(
                            "Name: ${givenDogs[index].name}",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Breed: ${givenDogs[index].breed}",
                            style: TextStyle(fontSize: 10, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.white, size: 16),
                      onPressed: () {
                        deleteGivenDog(givenDogs[index]);
                      },
                    ),
                  ],
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
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage('https://scontent.fmnl17-1.fna.fbcdn.net/v/t39.30808-1/475796915_1278283660123368_4722941500218312188_n.jpg?stp=dst-jpg_s200x200_tt6&_nc_cat=100&ccb=1-7&_nc_sid=1d2534&_nc_eui2=AeFp1VZMql_qMUuSSOKdargRdZbAhKIbJsh1lsCEohsmyPYq9Qfr1pfxvUtNMIy7s7oFqRdHrZLgof45-0QKnSJM&_nc_ohc=rHUHt4fQeVMQ7kNvgGKGTv9&_nc_oc=AdimVi6bbig9v2SX-s7diaocLa36JXb2Zb15qAPY6iLJEgTHDhZtZg8lr-5YC_q_QYs&_nc_zt=24&_nc_ht=scontent.fmnl17-1.fna&_nc_gid=Akf37xIH56ZUbldYflcZ4JG&oh=00_AYAhgde-q4a-5APmsp8NgQr8lCt8_IQlTZUutuuQt_gQpQ&oe=67C888DA'),
              ),
              SizedBox(height: 16),
              Text(
                'Linson',
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
                    'Hi, I am Linson, and I am passionate about giving dogs a second chance at a loving home! This page is dedicated to helping rescue dogs find their forever families. Whether you are looking to adopt, learn about responsible pet ownership, or support rescued pups, you are in the right place. Join me in making a difference—one wagging tail at a time! 🐶❤️',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                 
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
              icon: Icon(Icons.favorite), label: 'Adopted Dogs'),
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