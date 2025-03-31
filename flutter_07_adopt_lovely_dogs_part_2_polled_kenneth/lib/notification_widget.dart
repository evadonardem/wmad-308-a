import 'dart:ui';
import 'package:flutter/material.dart';

class NotificationWidget extends StatelessWidget {
  final String message;

  const NotificationWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
            border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 1.0),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            message,
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
