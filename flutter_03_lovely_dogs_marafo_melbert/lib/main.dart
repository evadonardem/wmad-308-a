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
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 18, 28, 83)),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  late Future<List<String>> futureBreeds;
  Future<String>? futureSelectedImageUrl;
  bool hasSelection = false;
  var wordPair = "";

  @override
  void initState() {
    super.initState();
    futureBreeds = fetchBreeds();
  }

  void handleBreedSelection(String breed) {
    setState(() {
      wordPair = WordPair.random().join("");
      hasSelection = true;
      futureSelectedImageUrl = fetchRandomAnimalFromBreed(breed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Select a Dog Breed",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder<List<String>>(
                future: futureBreeds,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    var breeds = snapshot.data!;
                    return DropdownMenu(
                      dropdownMenuEntries: breeds
                          .map((breed) => DropdownMenuEntry(
                              value: breed, label: breed.toUpperCase()))
                          .toList(),
                      onSelected: (value) {
                        if (value != null) handleBreedSelection(value);
                      },
                    );
                  }
                  return const Text("No breeds found.");
                }),
            if (hasSelection && futureSelectedImageUrl != null)
              FutureBuilder<String>(
                  future: futureSelectedImageUrl,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('${snapshot.error}');
                    } else if (snapshot.hasData) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          snapshot.data!,
                          height: 300,
                        ),
                      );
                    }
                    return const SizedBox();
                  }),
            Text(
              wordPair.toUpperCase(),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),)
          ],
        ),
      ),
    );
  }
}

Future<List<String>> fetchBreeds() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<String> breeds = List.from(data['message'].keys);
    return breeds;
  } else {
    throw Exception('Failed to fetch breeds');
  }
}

Future<String> fetchRandomAnimalFromBreed(String breed) async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('Failed to fetch image from breed');
  }
}
