import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dogs1/main.dart'; // Ensure the correct path

void main() {
  testWidgets('Dog Adoption App Smoke Test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(DogAdoptionApp());

    // Verify "Adopt ❤️" button exists
    expect(find.text('Adopt ❤️'), findsOneWidget);

    // Verify "Pass ❌" button exists
    expect(find.text('Pass ❌'), findsOneWidget);

    // Tap "Adopt ❤️" button
    await tester.tap(find.text('Adopt ❤️'));
    await tester.pumpAndSettle();

    // Verify a new image appears (as we can't check the exact image, we check for any Image widget)
    expect(find.byType(Image), findsWidgets);
  });
}
