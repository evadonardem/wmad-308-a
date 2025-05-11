
class Dog {
  final int? id;
  final String name;
  final String breed;
  final String imageUrl;

  Dog({
    this.id,
    required this.name,
    required this.breed,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'imageUrl': imageUrl,
    };
  }

  factory Dog.fromMap(Map<String, dynamic> map) {
    return Dog(
      id: map['id'] as int?,
      name: map['name'] as String,
      breed: map['breed'] as String,
      imageUrl: map['imageUrl'] as String,
    );
  }

  factory Dog.withRandomName(String breed, String imageUrl) {
    final randomName = 'Dog_${DateTime.now().millisecondsSinceEpoch}';
    return Dog(name: randomName, breed: breed, imageUrl: imageUrl);
  }
}