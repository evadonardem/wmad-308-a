import 'package:flutter/material.dart';
import '../../models/dog.dart';

class HomeRightSection extends StatelessWidget {
  final TextEditingController searchController;
  final List<Dog> filteredDogs;
  final Function(Dog) handleDogSelection;
  final Function(String) filterDogs;

  const HomeRightSection({
    super.key,
    required this.searchController,
    required this.filteredDogs,
    required this.handleDogSelection,
    required this.filterDogs,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double searchWidth = constraints.maxWidth * 0.8;
        double gridWidth = constraints.maxWidth * 0.9;
        int crossAxisCount = (constraints.maxWidth ~/ 150).clamp(2, 6);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: searchWidth,
                child: TextField(
                  controller: searchController,
                  cursorWidth: 3.0,
                  cursorColor: Colors.yellow,
                  decoration: InputDecoration(
                    hintText: "Type to search...",
                    hintStyle: TextStyle(color: Colors.white),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  style: TextStyle(color: Colors.white),
                  onChanged: filterDogs,
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: gridWidth,
                constraints: BoxConstraints(maxHeight: 500),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 4.5,
                  ),
                  itemCount: filteredDogs.length,
                  itemBuilder: (context, index) {
                    bool isHovered = false;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return MouseRegion(
                          onEnter: (_) {
                            setState(() {
                              isHovered = true;
                            });
                          },
                          onExit: (_) {
                            setState(() {
                              isHovered = false;
                            });
                          },
                          child: GestureDetector(
                            onTap: () {
                              handleDogSelection(filteredDogs[index]);
                            },
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isHovered ? Colors.white : Colors.transparent,
                                border: Border.all(
                                  color: Color(0xFF8D99AE),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: isHovered
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                filteredDogs[index].breed.toUpperCase(),
                                style: TextStyle(
                                  color: isHovered ? Colors.black : Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
