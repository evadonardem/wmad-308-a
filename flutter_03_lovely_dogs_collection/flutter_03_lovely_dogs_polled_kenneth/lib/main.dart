import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class DogBreed {
  final String name;
  
  const DogBreed ({required this.name});

  factory DogBreed.fromJson(Map<String, dynamic> json){
    return switch(json) {
      {'name' :String name} => DogBreed(
        name: name,
        ),
        _ => throw const FormatException('FAILED to load dog breeds.'),
    };
  }
}

Future fetchDogBreeds() async{
  var dogBreedsEndpoint = "https://dog.ceo/api/breeds/list/all";
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      var breeds = data['message'].keys.map(
        (key) => {"name": key},
      );
      
    return 'Sucess';
  } else {
    print(response.statusCode);
      throw Exception('FAILED to load dog breed');
  }
}

class MyApp extends StatelessWidget{
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
  late Future<List<String> futureDogBreeds;
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    futureDogBreeds = fetchDogBreeds();

  }
  void _incrementCounter(){
    setState(() {

      _counter++;
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
        child : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder(
              future: futureDogBreeds,
              builder: (context, snapchat) {
                if (snapchat.hasData) {
                print (snapchat.data);
                return DropdownMenu(dropdownMenuEntries: [],);
              }else if(snapchat.hasError){
                return Text ('may error');
              }
            )
          ],
        ),
      ),
    );
  }
}