import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart' show WordPair;
import 'dart:developer' as developer;
import '../main.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key, 
    required this.title,
    required this.adoptedDogs,
    required this.showNotification,
  });

  final String title;
  final List<AdoptedDog> adoptedDogs;
  final void Function(String) showNotification;

  @override
  State<MyHomePage> createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late Future<List<DogBreed>> futureDogBreeds;
  List<DogBreed> allBreeds = [];
  List<DogBreed> filteredBreeds = [];
  DogBreed? selectedBreed;
  String? dogImageUrl;
  String? dogName;
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  bool isDropdownVisible = false;
  String? selectedBreedImageUrl;
  int? _hoveredIndex;

  late AnimationController _controller;
  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _searchBarAnimation;
  late AnimationController _revealAnimationController;
  late Animation<double> _revealAnimation;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
    futureDogBreeds.then((breeds) {
      setState(() {
        allBreeds = breeds;
        filteredBreeds = breeds;
      });
    });

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _titleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _subtitleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 0.75, curve: Curves.easeOut),
    );

    _searchBarAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    _revealAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _revealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _revealAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (dogImageUrl != null && oldWidget is MyHomePage && oldWidget.title != widget.title) {
      _revealAnimationController.reset();
      _revealAnimationController.forward();
    }
  }

  void resetHomePage() {
    _controller.reset();
    _controller.forward();
    _resetScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    _revealAnimationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    setState(() {
      isDropdownVisible = !isDropdownVisible;
    });
  }

  Future<void> _fetchBreedImage(String breed) async {
    try {
      final imageUrl = await fetchDogImage(breed.toLowerCase());
      setState(() {
        selectedBreedImageUrl = imageUrl;
      });
    } catch (e) {
      developer.log('Error fetching breed image: $e', level: 1);
    }
  }

  void _onBreedSelected(DogBreed? breed) async {
    if (breed != null && filteredBreeds.contains(breed)) {
      setState(() {
        selectedBreed = breed;
        searchController.text = breed.name;
        isLoading = true;
      });
      await _fetchBreedImage(breed.name);
      await _fetchNewDog(breed);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchNewDog(DogBreed breed) async {
    final imageUrl = await fetchDogImage(breed.name.toLowerCase());
    setState(() {
      selectedBreed = breed;
      dogImageUrl = imageUrl;
      dogName = WordPair.random().asPascalCase;
    });
    _revealAnimationController.reset();
    _revealAnimationController.forward();
  }

  void _showAnotherDog() async {
    if (selectedBreed != null) {
      setState(() {
        isLoading = true;
      });
      final imageUrl = await fetchDogImage(selectedBreed!.name.toLowerCase());
      setState(() {
        dogImageUrl = imageUrl;
        dogName = WordPair.random().asPascalCase;
        isLoading = false;
      });
      _revealAnimationController.reset();
      _revealAnimationController.forward();
    }
  }

  void _adoptDog() async {
    if (selectedBreed != null && dogImageUrl != null && dogName != null) {
      final dbHelper = DatabaseHelper.instance;
      final existingDogs = await dbHelper.fetchAdoptedDogs();
      if (existingDogs.any((dog) => dog.name == dogName)) {
        widget.showNotification('This dog is already adopted choose another one');
        return;
      }
      final newDog = AdoptedDog(
        breed: selectedBreed!.name,
        imageUrl: dogImageUrl!,
        name: dogName!,
      );
      try {
        await dbHelper.insertAdoptedDog(newDog);
        setState(() {
          widget.adoptedDogs.add(newDog);
        });
        widget.showNotification('You have adopted $dogName');
      } catch (e) {
        developer.log('Error inserting adopted dog: $e', level: 1);
      }
    }
  }

  void _filterBreeds(String query) {
    setState(() {
      filteredBreeds = allBreeds
          .where((breed) => breed.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _resetScreen() {
    setState(() {
      selectedBreed = null;
      selectedBreedImageUrl = null;
      dogImageUrl = null;
      dogName = null;
      searchController.clear();
      isDropdownVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FadeTransition(
                    opacity: _titleAnimation,
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.black,
                            fontSize: 40,
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 4.0,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  FadeTransition(
                    opacity: _subtitleAnimation,
                    child: const Text(
                      '"Home of the best dogs"',
                      style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Orbitron'),
                    ),
                  ),
                  FadeTransition(
                    opacity: _searchBarAnimation,
                    child: FutureBuilder<List<DogBreed>>(
                      future: futureDogBreeds,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.black, fontFamily: 'Orbitron'),
                          );
                        } else if (snapshot.hasData) {
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Container(
                                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.7),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            if (selectedBreedImageUrl != null)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 8.0),
                                                child: Image.network(
                                                  selectedBreedImageUrl!,
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            Expanded(
                                              child: TextField(
                                                controller: searchController,
                                                onChanged: (query) {
                                                  _filterBreeds(query);
                                                  setState(() {
                                                    isDropdownVisible = query.isNotEmpty;
                                                  });
                                                },
                                                decoration: const InputDecoration(
                                                  hintText: 'Search dog breeds or press the arrow down to show breeds...',
                                                  hintStyle: TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                                                ),
                                                style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
                                                cursorColor: Colors.white,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                                              onPressed: _toggleDropdown,
                                            ),
                                          ],
                                        ),
                                        if (isDropdownVisible)
                                          Container(
                                            height: 120,
                                            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                                            child: ListView.builder(
                                              itemCount: filteredBreeds.length,
                                              itemBuilder: (context, index) {
                                                final breed = filteredBreeds[index];
                                                return MouseRegion(
                                                  onEnter: (_) => setState(() => _hoveredIndex = index),
                                                  onExit: (_) => setState(() => _hoveredIndex = null),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      _onBreedSelected(breed);
                                                      setState(() => isDropdownVisible = false);
                                                    },
                                                    child: Container(
                                                      color: _hoveredIndex == index
                                                          ? Colors.grey[600]
                                                          : Colors.transparent,
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(
                                                          vertical: 4.0,
                                                          horizontal: 8.0),
                                                        child: Row(
                                                          children: [
                                                            FutureBuilder<String>(
                                                              future: fetchDogImage(breed.name.toLowerCase()),
                                                              builder: (context, snapshot) {
                                                                if (snapshot.connectionState == ConnectionState.waiting) {
                                                                  return const SizedBox(
                                                                    width: 40,
                                                                    height: 40,
                                                                    child: CircularProgressIndicator(
                                                                      strokeWidth: 2,
                                                                      color: Colors.grey,
                                                                    ),
                                                                  );
                                                                } else if (snapshot.hasError) {
                                                                  return const Icon(Icons.error, color: Colors.red, size: 40);
                                                                } else if (snapshot.hasData) {
                                                                  return Image.network(
                                                                    snapshot.data!,
                                                                    width: 40,
                                                                    height: 40,
                                                                    fit: BoxFit.fill,
                                                                  );
                                                                }
                                                                return const SizedBox.shrink();
                                                              },
                                                            ),
                                                            const SizedBox(width: 8.0),
                                                            Expanded(
                                                              child: Text(
                                                                breed.name,
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontFamily: 'Orbitron',
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const Text(
                          'No data available',
                          style: TextStyle(color: Colors.black, fontFamily: 'Orbitron'),
                        );
                      },
                    ),
                  ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 0, 0, 0),
                        strokeWidth: 4.0,
                      ),
                    )
                  else if (dogImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _revealAnimationController,
                            builder: (context, child) {
                              return ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: _revealAnimation.value,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width * 0.4,
                                    height: MediaQuery.of(context).size.height * 0.5,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(color: Colors.white, width: 3.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8.0),
                                        child: Stack(
                                          children: [
                                            Container(
                                              color: Colors.grey[800],
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                            Image.network(
                                              dogImageUrl!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.fill,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _revealAnimationController,
                            builder: (context, child) {
                              return ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: _revealAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(color: Colors.white, width: 2.0),
                                    ),
                                    child: Text(
                                      'Name: $dogName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontFamily: 'Orbitron',
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          AnimatedBuilder(
                            animation: _revealAnimationController,
                            builder: (context, child) {
                              return ClipRect(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  heightFactor: _revealAnimation.value,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      MouseRegion(
                                        child: ElevatedButton(
                                          onPressed: _adoptDog,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.white),
                                          ).copyWith(
                                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                                              if (states.contains(MaterialState.hovered)) return Colors.grey[800];
                                              return Colors.black;
                                            }),
                                          ),
                                          child: const Text('Adopt Me', style: TextStyle(fontFamily: 'Orbitron')),
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      MouseRegion(
                                        child: ElevatedButton(
                                          onPressed: _showAnotherDog,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                            foregroundColor: Colors.white,
                                            side: const BorderSide(color: Colors.white),
                                          ).copyWith(
                                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                                              if (states.contains(MaterialState.hovered)) return Colors.grey[800];
                                              return Colors.black;
                                            }),
                                          ),
                                          child: const Text('Show Me Another Dog', style: TextStyle(fontFamily: 'Orbitron')),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}