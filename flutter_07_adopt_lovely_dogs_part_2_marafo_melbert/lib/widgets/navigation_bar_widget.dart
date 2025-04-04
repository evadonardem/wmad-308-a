import 'package:flutter/material.dart';

class NavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const NavigationBarWidget({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemTapped,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.blue,
      unselectedItemColor: const Color.fromARGB(255, 63, 63, 63),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
          tooltip: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: 'Adopted',
          tooltip: 'Adopted',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.card_giftcard),
          label: 'Give Away',
          tooltip: 'Give Away',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info),
          label: 'About',
          tooltip: 'About',
        ),
      ],
    );
  }
}
