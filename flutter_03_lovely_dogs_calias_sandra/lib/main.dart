import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

Future<List<String>> fetchDogBreeds() async {
  final dogBreedsEndpont = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpont));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return List.from(data['message'].keys);
  } else {
    throw Exception('Failed to load album');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  late Future<List<String>> futureDogBreeds;

  

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();
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
            FutureBuilder(
                future: futureDogBreeds,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final List<DropdownMenuEntry> dropdownMenuEntriesDogBreeds =
                     snapshot.requireData
                        .map((name) => DropdownMenuEntry(
                            value: name, label: name.toUpperCase()))
                        .toList();

                    return DropdownMenu(
                      dropdownMenuEntries: dropdownMenuEntriesDogBreeds, 
                      onSelected: (value) {
                        print('napili: ' + value);                    
                        },  
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                }),
                Image.network('https://images.dog.ceo/breeds/hound-plott/hhh-23456.jpg')
          ],
        ),
      ),
    );
  }
}
