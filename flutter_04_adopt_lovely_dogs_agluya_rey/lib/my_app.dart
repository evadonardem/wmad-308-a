import 'package:flutter/material.dart';
import 'my_home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dog',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: Color(0xFF2B2D42),
          primaryContainer: Color(0xFF8D99AE),
          secondary: Color(0xFFEDF2F4),
          secondaryContainer: Color(0xFF8D99AE),
          surface: Color(0xFF2B2D42),
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