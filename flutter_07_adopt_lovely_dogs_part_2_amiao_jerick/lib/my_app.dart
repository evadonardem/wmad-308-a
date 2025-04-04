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
          primary: Color(0xFFAA60C8),
          primaryContainer: Color(0xFFD69ADE),
          secondary: Color(0xFFEABDE6),
          secondaryContainer: Color(0xFFD69ADE),
          surface: Color(0xFFAA60C8),
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
          onError: Colors.white,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}