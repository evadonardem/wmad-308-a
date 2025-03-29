
// lib/screens/adopted_dogs_page.dart

import 'package:flutter/material.dart';
import '../models.dart';

class AdoptedDogsPage extends StatefulWidget {
  final List<Dog> adoptedDogs;
  final Function(Dog) onGiveAway;

  const AdoptedDogsPage({
    super.key,
    required this.adoptedDogs,
    required this.onGiveAway,
  });

  @override
  State<AdoptedDogsPage> createState() => _AdoptedDogsPageState();
}

class _AdoptedDogsPageState extends State<AdoptedDogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
                      "ADOPTED DOGS",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 20,
                        fontFamily: 'SigmarFont',
                      ),
                    ),
        centerTitle: true, 
      ),
      body: widget.adoptedDogs.isEmpty
          ? const Center(
              child: Text("No adopted dogs yet!"),
            )
          : ListView.builder(
              itemCount: widget.adoptedDogs.length,
              itemBuilder: (context, index) {
                final dog = widget.adoptedDogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            dog.imageUrl,
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dog.name.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dog.breed,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            widget.onGiveAway(dog);

                            setState(() {
                              widget.adoptedDogs.remove(dog);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${dog.name.toUpperCase()} has been given away. 🐶"),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Give Away"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
