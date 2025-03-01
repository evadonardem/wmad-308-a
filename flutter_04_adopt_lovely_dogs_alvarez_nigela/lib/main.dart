import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class DogBreed {
  final String name;
  const DogBreed({required this.name});

  factory DogBreed.fromJson(Map<String, dynamic> json) {
    return DogBreed(name: json['name'] as String);
  }
}

Future<List<DogBreed>> fetchDogBreeds() async {
  var dogBreedsEndpoint = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    var breeds =
        (data['message'] as Map<String, dynamic>).keys
            .map((key) => DogBreed(name: key))
            .toList();
    return breeds;
  } else {
    throw Exception('FAILED to load dog breeds');
  }
}

Future<String> fetchBreedImage(String breed) async {
  var breedImageEndpoint = "https://dog.ceo/api/breed/$breed/images/random";
  final response = await http.get(Uri.parse(breedImageEndpoint));

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['message'] as String;
  } else {
    throw Exception('Failed to load breed image');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADOPT A DOG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 12, 11, 14),
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
  late Future<List<DogBreed>> futureDogBreeds;
  DogBreed? selectedBreed;
  String? breedImageUrl;
  String? randomDogName;
  bool isImageLoading = false;

  final List<String> randomNames = [
    'Bogart',
    'Maxine',
    'Bella',
    'Lucie',
    'Momo',
    'Nancy',
    'Rocky',
    'Daisy',
    'Mico',
    'Zoey',
  ];

  List<Map<String, String>> adoptedDogs = [];
  List<Map<String, String>> giveawayDogs = [];

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }

  String getRandomName() {
    final random = Random();
    return randomNames[random.nextInt(randomNames.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(''),
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF9ACD32),
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.purple,
        selectedLabelStyle: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(color: Colors.purple),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopted'),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Giveaway',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'About'),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        currentIndex: _selectedIndex,
      ),
    );
  }

  int _selectedIndex = 0;

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return _homePageContent();
      case 1:
        return _adoptedPageContent();
      case 2:
        return _giveawayPageContent();
      case 3:
        return _aboutPageContent();
      default:
        return _homePageContent();
    }
  }

  Widget _homePageContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // New Text about adoption
          Text(
            'Adopt a Dog and Give Them a Loving Home!',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'We have adorable dogs waiting for a loving home.\nPlease explore and adopt your new best friend!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Existing Content (Breed Selector, Name, Image, etc.)
          FutureBuilder<List<DogBreed>>(
            future: futureDogBreeds,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return DropdownButton<DogBreed>(
                  value: selectedBreed,
                  hint: Text('Select a breed'),
                  items:
                      snapshot.data!.map((DogBreed breed) {
                        return DropdownMenuItem<DogBreed>(
                          value: breed,
                          child: Text(breed.name),
                        );
                      }).toList(),
                  onChanged: (DogBreed? newValue) {
                    setState(() {
                      selectedBreed = newValue;
                      breedImageUrl = null;
                      randomDogName = getRandomName();
                      isImageLoading =
                          true; // Set the loading to true when we are fetching the image
                    });

                    // Introduce a small delay before showing the loader
                    Future.delayed(Duration(milliseconds: 200), () {
                      if (newValue != null) {
                        fetchBreedImage(newValue.name)
                            .then((imageUrl) {
                              setState(() {
                                breedImageUrl = imageUrl;
                                isImageLoading =
                                    false; // Hide loader when image is fetched
                              });
                            })
                            .catchError((error) {
                              setState(() {
                                breedImageUrl = null;
                                isImageLoading =
                                    false; // Hide loader in case of error
                              });
                            });
                      }
                    });
                  },
                );
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return const CircularProgressIndicator();
            },
          ),
          if (selectedBreed != null)
            Text(
              '$randomDogName', // Show breed and random name
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          if (breedImageUrl != null)
            Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Show image here
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.network(
                        breedImageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) {
                            return child;
                          } else {
                            // Display a loader while the image is loading
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    if (isImageLoading) ...[
                      // This is the loader that shows until the image is loaded
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          const SizedBox(height: 20),
          // Adopt Button
          ElevatedButton(
            onPressed: () {
              if (selectedBreed != null && breedImageUrl != null) {
                setState(() {
                  adoptedDogs.add({
                    'name': randomDogName!,
                    'imageUrl': breedImageUrl!,
                    'breed': selectedBreed!.name,
                  });
                });
                print('Adopted $randomDogName!');
              }
            },
            child: Text("Adopt"),
          ),
          const SizedBox(height: 20), // Space between buttons
          // Show Another Dog Button with loader indication
          ElevatedButton(
            onPressed: () {
              if (selectedBreed != null) {
                setState(() {
                  randomDogName =
                      getRandomName(); // Generate a new random dog name
                  breedImageUrl = null; // Reset the breed image first
                  isImageLoading = true; // Show loader
                });

                // Fetch a new image for the selected breed
                fetchBreedImage(selectedBreed!.name)
                    .then((imageUrl) {
                      setState(() {
                        breedImageUrl = imageUrl; // Update the breed image
                        isImageLoading = false; // Hide loader
                      });
                    })
                    .catchError((error) {
                      setState(() {
                        breedImageUrl = null; // Handle error case
                        isImageLoading = false; // Hide loader
                      });
                    });
              }
            },
            child:
                isImageLoading
                    ? CircularProgressIndicator() // Show loader if fetching image
                    : Text("Show Me Another Dog"),
          ),
        ],
      ),
    );
  }

  Widget _adoptedPageContent() {
    return ListView.builder(
      itemCount: adoptedDogs.length,
      itemBuilder: (context, index) {
        final dog = adoptedDogs[index];
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.amber[(index % 3 + 1) * 200],
          child: ListTile(
            leading: Image.network(
              dog['imageUrl']!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(dog['name']!),
            subtitle: Text('Breed: ${dog['breed']}'),
            trailing: TextButton(
              onPressed: () {
                setState(() {
                  giveawayDogs.add(dog);
                  adoptedDogs.removeAt(index);
                });
              },
              child: Text('Giveaway'),
            ),
          ),
        );
      },
    );
  }

  Widget _giveawayPageContent() {
    return ListView.builder(
      itemCount: giveawayDogs.length,
      itemBuilder: (context, index) {
        final dog = giveawayDogs[index];
        return Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: Colors.green[(index % 3 + 1) * 200],
          child: ListTile(
            leading: Image.network(
              dog['imageUrl']!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(dog['name']!),
            subtitle: Text('Breed: ${dog['breed']}'), // Added breed info
          ),
        );
      },
    );
  }

  Widget _aboutPageContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('About Us'),
          Text(
            'We are passionate about dogs and want to give them the love they deserve.\n'
            'Help us find loving homes for our adorable dogs!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
