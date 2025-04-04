class Dog {
  final int? id;
  final String imageUrl;
  final String status;

  Dog({
    this.id,
    required this.imageUrl,
    required this.status,
  });

  // Convert Dog object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  // Convert Map to Dog object
  factory Dog.fromMap(Map<String, dynamic> map) {
    return Dog(
      id: map['id'],
      imageUrl: map['imageUrl'],
      status: map['status'],
    );
  }
}
