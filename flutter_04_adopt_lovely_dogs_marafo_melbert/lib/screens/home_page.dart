import 'package:flutter/material.dart';
import '../models.dart';
import '../utils.dart'; // Import Dog model

class HomePage extends StatefulWidget {
  final void Function(Dog) onAdopt;
  final List<Dog> dogs;

  const HomePage({super.key, required this.onAdopt, required this.dogs});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Dog? selectedDog;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    if (widget.dogs.isNotEmpty) {
      selectedDog = selectedDog ?? widget.dogs.first;
    } else {
      _loadDogs();
    }
  }

  Future<void> _loadDogs() async {
    if (widget.dogs.isNotEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      List<Dog> fetchedDogs = await fetchDogs();
      if (mounted) {
        setState(() {
          widget.dogs.addAll(fetchedDogs);
          selectedDog = selectedDog ??
              (fetchedDogs.isNotEmpty ? fetchedDogs.first : null);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _selectBreed(Dog dog) {
    setState(() {
      selectedDog = dog;
    });
  }

  void _adoptDog() {
    if (selectedDog != null) {
      widget.onAdopt(selectedDog!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("${selectedDog!.name.toUpperCase()} has been adopted! 🐶"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _findAnotherDog() async {
    if (selectedDog != null) {
      setState(() {
        isLoading = true;
      });

      try {
        Dog newDog = await fetchRandomDogImage(selectedDog!.breed);
        if (mounted) {
          setState(() {
            selectedDog = newDog;
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to fetch another dog. Try again!"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: Center(
                      child: Text(
                        "PAW ADOPT",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 48,
                          fontFamily: 'SigmarFont',
                        ),
                      ),
                    ),
                  ),
                  DropdownMenu<Dog>(
                    label: Text("Select a breed"),
                    enableSearch: true,
                    initialSelection: selectedDog,
                    dropdownMenuEntries: widget.dogs
                        .map((dog) => DropdownMenuEntry(
                              value: dog,
                              label: dog.breed.toUpperCase(),
                            ))
                        .toList(),
                    onSelected: (Dog? newSelectedDog) {
                      if (newSelectedDog != null) {
                        _selectBreed(newSelectedDog);
                      }
                    },
                  ),
                  if (selectedDog != null)
                    Column(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  20), 
                              child: Image.network(
                                selectedDog!.imageUrl,
                                height: 250,
                                width: 250, 
                                fit: BoxFit.cover, 
                              ),
                            )),
                        Text(
                          selectedDog!.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          selectedDog!.breed,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color.fromRGBO(75, 75, 75, 1),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _adoptDog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,  
                          children: const [
                            Icon(Icons.pets, color: Colors.white), 
                            SizedBox(width: 10), 
                            Text("Adopt this"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _findAnotherDog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,  
                          children: const [
                            Icon(Icons.search, color: Colors.white,), 
                            SizedBox(width: 10), 
                            Text("Find Another"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
