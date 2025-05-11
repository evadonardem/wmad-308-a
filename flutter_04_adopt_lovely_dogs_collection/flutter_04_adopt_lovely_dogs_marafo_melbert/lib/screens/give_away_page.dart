import 'package:flutter/material.dart';
import 'package:flutter_03_lovely_dogs_marafo_melbert/models.dart';

class GiveAwayPage extends StatefulWidget {
  final List<Dog> giveAwayDogs;

  const GiveAwayPage({super.key, required this.giveAwayDogs});

  @override
  State<GiveAwayPage> createState() => _GiveAwayPageState();
}

class _GiveAwayPageState extends State<GiveAwayPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
                      "GIVE AWAY DOGS",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 20,
                        fontFamily: 'SigmarFont',
                      ),
                    ),
        centerTitle: true,
      ),
      body: widget.giveAwayDogs.isEmpty
          ? const Center(
              child: Text("No dogs have been given away yet."),
            )
          : ListView.builder(
              itemCount: widget.giveAwayDogs.length,
              itemBuilder: (context, index) {
                final dog = widget.giveAwayDogs[index];
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
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
