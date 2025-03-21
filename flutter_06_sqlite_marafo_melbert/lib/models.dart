
class Dog {
  final id;
  final String name;
  final String breed;
  final String photo;

  Dog({this.id, required this.name, required this.breed, required this.photo});

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'breed': breed, 'photo': photo};
  }

  @override
  String toString() {
    return 'Dog{name: $name, breed: $breed, photo: $photo}';
  }  
}