import 'package:flutter/material.dart';
import '../../models/dog.dart';

class HomeLeftSection extends StatelessWidget {
  final bool hasSelection;
  final bool isLoadingImage;
  final Future<Dog>? futureSelectedDog;
  final Dog? selectedDog;
  final Function(Dog) likeDog;
  final VoidCallback fetchNextDog;

  const HomeLeftSection({
    super.key,
    required this.hasSelection,
    required this.isLoadingImage,
    required this.futureSelectedDog,
    required this.selectedDog,
    required this.likeDog,
    required this.fetchNextDog,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, top: 60.0), // Move card further left
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasSelection)
            isLoadingImage
                ? const CircularProgressIndicator(color: Color(0xFF8D99AE))
                : FutureBuilder<Dog>(
                    future: futureSelectedDog,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                            ),
                            Container(
                              width: 300,
                              height: 450,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(40),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Image.network(
                                        snapshot.data!.imageUrl,
                                        width: 280,
                                        height: 270,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 270,
                                            width: 270,
                                            color: Colors.grey,
                                            child: Icon(Icons.broken_image,
                                                color: Colors.white),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              snapshot.data!.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w500,
                                                color: const Color.fromARGB(
                                                    255, 255, 255, 255),
                                              ),
                                            ),
                                            SizedBox(height: 16),
                                            Column(
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    likeDog(snapshot.data!);
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color.fromARGB(255, 222, 4, 113),
                                                    shadowColor: Colors.white,
                                                    elevation: 0,
                                                    minimumSize: Size(280, 20), // Match half the image height
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.favorite,
                                                    color: Colors.white,
                                                    size: 30,
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                ElevatedButton(
                                                  onPressed: fetchNextDog,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Color.fromARGB(255, 59, 136, 224),
                                                    shadowColor: Colors.white,
                                                    elevation: 0,
                                                    minimumSize: Size(280, 20), // Match half the image height
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.navigate_next,
                                                    color: Colors.white,
                                                    size: 30,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox();
                    },
                  ),
        ],
      ),
    );
  }
}