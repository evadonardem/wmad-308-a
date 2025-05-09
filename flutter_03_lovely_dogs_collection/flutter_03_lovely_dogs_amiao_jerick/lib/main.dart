import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:english_words/english_words.dart';


void main() {
  runApp(const MyApp());
}


Future<List<String>> fetchDogBreeds() async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));


  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List<String>.from(data['message'].keys);
  } else {
    throw Exception('Failed to load breeds');
  }
}


Future<String> fetchDogImage(String breed) async {
  final response = await http.get(Uri.parse('https://dog.ceo/api/breed/$breed/images/random'));


  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message']; // Image URL
  } else {
    throw Exception('Failed to load image');
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dog Breeds & Album',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: '🐶 Dog Breeds & Album Explorer'),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;


  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


class _MyHomePageState extends State<MyHomePage> {
  late Future<List<String>> futureDogBreeds;
  String? selectedBreed;
  String? dogImageUrl;
  String dogName = WordPair.random().asPascalCase;
  bool isLoading = false; // Track loading state


  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
  }


  void updateDogImage(String breed) async {
    setState(() {
      isLoading = true; // Start loading
      dogImageUrl = null; // Reset image
    });


    try {
      final imageUrl = await fetchDogImage(breed);
      setState(() {
        dogImageUrl = imageUrl;
        dogName = WordPair.random().asPascalCase; // Generate new name
        isLoading = false; // Stop loading
      });
    } catch (e) {
      print("Error fetching image: $e");
      setState(() {
        isLoading = false; // Stop loading even if there's an error
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: snapshot.data!.map((breed) {
                    return DropdownMenuItem(value: breed, child: Text(breed));
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
            if (isLoading) // Show loading indicator while fetching image
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text(
                    "Loading image...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              )
            else if (dogImageUrl != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      dogImageUrl!,
                      width: 350,
                      height: 350,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "🐾 Name: $dogName",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else
              const Text(
                "🐾 Select a breed to see its image",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
          ],
        ),
      ),
    );
  }
}
