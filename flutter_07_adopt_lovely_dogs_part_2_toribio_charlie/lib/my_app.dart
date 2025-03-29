import 'package:flutter/material.dart';
import 'pages/my_home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dog',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: Color.fromARGB(255, 0, 0, 0),
          primaryContainer: Color(0xFFD69ADE),
          secondary: Color.fromARGB(255, 0, 0, 0),
          secondaryContainer: Color(0xFFD69ADE),
          surface: Color.fromARGB(255, 255, 255, 255),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.black, // Ensure text is visible on dropdown surfaces
          onError: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}