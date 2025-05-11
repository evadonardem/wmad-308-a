import 'package:flutter/material.dart';
import '../models/dog.dart';

class LikedDogsPage extends StatelessWidget {
  final List<Dog> likedDogs;
  final Map<int, TextEditingController> nameControllers;
  final Map<int, bool> isNameChanged;
  final Function(Dog) giveDog;
  final Function(int, String) updateDogName;

  const LikedDogsPage({
    super.key,
    required this.likedDogs,
    required this.nameControllers,
    required this.isNameChanged,
    required this.giveDog,
    required this.updateDogName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth / 200).floor().clamp(1, 6);

        return Center(
          child: SizedBox(
            width: constraints.maxWidth * 0.95,
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85, // Adjust aspect ratio to avoid overflow
              ),
              itemCount: likedDogs.length,
              itemBuilder: (context, index) {
                final dog = likedDogs[index];

                // Ensure controllers and state are initialized
                nameControllers.putIfAbsent(dog.id!, () => TextEditingController(text: dog.name));
                isNameChanged.putIfAbsent(dog.id!, () => false);

                final controller = nameControllers[dog.id!]!;

                return StatefulBuilder(
                  builder: (context, setState) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(108, 0, 0, 0),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            child: Image.network(
                              dog.imageUrl,
                              height: 100, // Reduce height to prevent overflow
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 100,
                                  color: const Color.fromARGB(255, 255, 255, 255),
                                  child: const Icon(Icons.broken_image, color: Colors.white),
                                );
                              },
                            ),
                          ),
                          Expanded( // Prevents overflow by allowing flexible space
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: controller,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Enter name',
                                      hintStyle: TextStyle(color: Colors.white),
                                    ),
                                    onChanged: (newName) {
                                      setState(() {
                                        isNameChanged[dog.id!] = newName != dog.name;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dog.breed,
                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                  ),
                                  const Spacer(), // Pushes buttons to bottom
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          giveDog(dog);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                                          shadowColor: Colors.white,
                                          elevation: 0,
                                          minimumSize: const Size(50, 30),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text(
                                          "Give",
                                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 12),
                                        ),
                                      ),
                                      if (isNameChanged[dog.id!]!)
                                        ElevatedButton(
                                          onPressed: () {
                                            if (controller.text.isNotEmpty && dog.id != null) {
                                              updateDogName(dog.id!, controller.text);
                                              setState(() {
                                                isNameChanged[dog.id!] = false;
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shadowColor: Colors.white,
                                            elevation: 0,
                                            minimumSize: const Size(50, 30),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            "Save",
                                            style: TextStyle(color: Colors.white, fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
