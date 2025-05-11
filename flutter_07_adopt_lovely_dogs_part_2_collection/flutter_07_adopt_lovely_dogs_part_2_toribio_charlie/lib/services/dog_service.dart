import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dog.dart';
import 'package:english_words/english_words.dart';

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
    throw Exception('Failed to fetch dogs: ${response.reasonPhrase}');
  }
}

Future<String> fetchRandomDogImageUrl(String breed) async {
  final dogImageEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('Failed to fetch image for breed: ${response.reasonPhrase}');
  }
}

Future<Dog> fetchRandomDogImage(String breed) async {
  final imageUrl = await fetchRandomDogImageUrl(breed);
  return Dog.withRandomName(breed, imageUrl);
}

Future<List<String>> fetchDogBreeds() async {
  final dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['message'] as Map<String, dynamic>).keys.toList();
  } else {
    throw Exception('Failed to fetch dog breeds: ${response.reasonPhrase}');
  }
}