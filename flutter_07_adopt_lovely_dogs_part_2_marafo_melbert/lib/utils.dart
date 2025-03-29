import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';
import 'database.dart';

Future<List<Dog>> fetchDogs() async {
  final db = DogDatabase.instance;

  List<Dog> storedDogs = await db.getAllDogs();
  if (storedDogs.isNotEmpty) {
    return storedDogs;
  }

  const dogBreedsEndpoint = 'https://dog.ceo/api/breeds/list/all';
  final response = await http.get(Uri.parse(dogBreedsEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    List<Dog> dogs = [];

    for (var breed in data['message'].keys) {
      try {
        final image = await fetchRandomDogImageUrl(breed);
        Dog dog = Dog.withRandomName(breed, image);
        dogs.add(dog);

        // Insert the dog into the database
        await db.addDog(dog, 'dogs');
      } catch (e) {
        // Log errors for specific breeds but continue processing others
        print('Error fetching image for breed $breed: $e');
      }
    }
    return dogs;
  } else {
    throw Exception('Failed to fetch dog breeds from API');
  }
}

Future<String> fetchRandomDogImageUrl(String breed) async {
  final dogImageEndpoint = 'https://dog.ceo/api/breed/$breed/images/random';
  final response = await http.get(Uri.parse(dogImageEndpoint));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['message'];
  } else {
    throw Exception('Failed to fetch image for breed $breed');
  }
}