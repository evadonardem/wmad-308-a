import 'package:flutter/material.dart';
import '../../models/dog.dart';

class HomeRightSection extends StatefulWidget {
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
  // ignore: library_private_types_in_public_api
  _HomeRightSectionState createState() => _HomeRightSectionState();
}

class _HomeRightSectionState extends State<HomeRightSection> {
  bool showDropdown = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double searchWidth = constraints.maxWidth * 0.8;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: searchWidth,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget.searchController,
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
                            onChanged: (query) {
                              widget.filterDogs(query);
                              setState(() {
                                showDropdown = true;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            showDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              showDropdown = !showDropdown;
                            });
                          },
                        ),
                      ],
                    ),
                    if (showDropdown && widget.filteredDogs.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Colors.transparent, // Set background to transparent
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: widget.filteredDogs.length,
                          separatorBuilder: (context, index) => Divider(
                            // ignore: deprecated_member_use
                            color: Colors.white.withOpacity(0.5),
                            thickness: 0.5,
                          ),
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(
                                widget.filteredDogs[index].breed,
                                style: TextStyle(color: Colors.white),
                              ),
                              onTap: () {
                                widget.handleDogSelection(widget.filteredDogs[index]);
                                setState(() {
                                  showDropdown = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
