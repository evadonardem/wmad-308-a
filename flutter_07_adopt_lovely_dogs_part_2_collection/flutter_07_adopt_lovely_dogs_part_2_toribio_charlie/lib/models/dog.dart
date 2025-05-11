import 'package:english_words/english_words.dart';

class Dog {
  final int? id;
  final String breed;
  final String name;
  final String imageUrl;

  Dog({this.id, required this.breed, required this.name, required this.imageUrl});

  factory Dog.withRandomName(String breed, String imageUrl) {
    return Dog(
        breed: breed, name: WordPair.random().join(""), imageUrl: imageUrl);
  }

  factory Dog.fromMap(Map<String, dynamic> map) {
    return Dog(
      id: map['id'],
      breed: map['breed'],
      name: map['name'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'breed': breed,
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}