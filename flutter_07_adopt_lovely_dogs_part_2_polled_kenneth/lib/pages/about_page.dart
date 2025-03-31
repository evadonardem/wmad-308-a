import 'package:flutter/material.dart';
import 'dart:ui';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
                      border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'About Homebound Hounds',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color.fromARGB(255, 255, 255, 255)),
                        ),
                        const SizedBox(height: 16.0),
                        const Text(
                          'Homebound Hounds is an app designed to help you find and adopt your perfect canine companion. '
                          'Browse through various dog breeds, view images, and adopt your favorite dogs. '
                          'You can also give away dogs that you have adopted if you can no longer take care of them.\n\n'
                          'Features:\n'
                          '- Browse different dog breeds\n'
                          '- View images of dogs\n'
                          '- Adopt dogs\n'
                          '- Give away dogs\n\n'
                          'We hope you find your perfect furry friend with Homebound Hounds!',
                          style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16, fontFamily: 'Orbitron'),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
