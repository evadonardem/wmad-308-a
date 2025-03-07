import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(DogAdoptionApp());
}

class DogAdoptionApp extends StatefulWidget {
  @override
  _DogAdoptionAppState createState() => _DogAdoptionAppState();
}

class _DogAdoptionAppState extends State<DogAdoptionApp> {
  int _selectedIndex = 0;
  String? selectedBreed;
  List<String> adoptedDogs = [];
  List<String> dislikedDogs = [];

  void _onBreedSelected(String breed) {
    setState(() {
      selectedBreed = breed;
      _selectedIndex = 0;
    });
  }

  void _onAdopt(String dogUrl) {
    setState(() {
      adoptedDogs.add(dogUrl);
    });
  }

  void _onDislike(String dogUrl) {
    setState(() {
      dislikedDogs.add(dogUrl);
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
      HistoryScreen(adoptedDogs: adoptedDogs, dislikedDogs: dislikedDogs),
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
          ? breed.toLowerCase().replaceAll(' ', '-')
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
    }
    fetchNewDog();
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

class BreedsScreen extends StatelessWidget {
  final Function(String) onBreedSelect;
  BreedsScreen({required this.onBreedSelect});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dog Breeds')),
      body: FutureBuilder(
        future: http.get(Uri.parse('https://dog.ceo/api/breeds/list/all')),
        builder: (context, AsyncSnapshot<http.Response> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data?.statusCode != 200) {
            return Center(child: Text('Failed to load breeds'));
          }

          final breeds =
              json.decode(snapshot.data!.body)['message'].keys.toList();
          return ListView.builder(
            itemCount: breeds.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(breeds[index]),
                onTap: () {
                  onBreedSelect(breeds[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final List<String> adoptedDogs;
  final List<String> dislikedDogs;

  HistoryScreen({required this.adoptedDogs, required this.dislikedDogs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adoption History')),
      body: ListView(
        children: [
          ...adoptedDogs.map((dog) => ListTile(
              leading: Image.network(dog, height: 50, width: 50),
              title: Text('Adopted Dog'))),
          Divider(),
          ...dislikedDogs.map((dog) => ListTile(
              leading: Image.network(dog, height: 50, width: 50),
              title: Text('Disliked Dog'))),
        ],
      ),
    );
  }
}
