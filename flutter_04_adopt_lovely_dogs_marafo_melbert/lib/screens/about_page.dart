import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "PAW ADOPT",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 48,
                fontFamily: 'SigmarFont', 
              ),
            ),
            const SizedBox(height: 20), 
            Text(
              "Developer: Melbert Marafo",
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey,
                fontFamily: 'SigmarFont',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
