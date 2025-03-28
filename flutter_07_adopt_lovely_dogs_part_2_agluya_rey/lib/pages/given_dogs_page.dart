import 'package:flutter/material.dart';
import '../models/dog.dart';

class GivenDogsPage extends StatelessWidget {
  final List<Dog> givenDogs;
  final Function(int) deleteDogFromGiven;

  const GivenDogsPage({
    super.key,
    required this.givenDogs,
    required this.deleteDogFromGiven,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = (constraints.maxWidth / 200).floor().clamp(1, 6);

        return Center(
          child: SizedBox(
            width: constraints.maxWidth * 0.9, // Adjust width dynamically
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.85, // Adjusted aspect ratio
              ),
              itemCount: givenDogs.length,
              itemBuilder: (context, index) {
                final dog = givenDogs[index];

                return Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(108, 141, 153, 174),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
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
                          height: 100, // Reduced height to prevent overflow
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey,
                              child: const Icon(Icons.broken_image, color: Colors.white),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dog.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dog.breed,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(), // Pushes delete button to bottom
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (dog.id != null) {
                                      deleteDogFromGiven(dog.id!);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shadowColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(50, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
