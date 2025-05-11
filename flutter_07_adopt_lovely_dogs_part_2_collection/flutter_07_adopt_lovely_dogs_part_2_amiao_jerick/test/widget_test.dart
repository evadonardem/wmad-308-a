import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_07_adopt_lovely_dogs_part_2_amiao_jerick/my_app.dart';

void main() {
  testWidgets('Dog selection and liking test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the initial page is the home page.
    expect(find.text('Select a Dog'), findsOneWidget);

    // Wait for the dogs to be fetched.
    await tester.pumpAndSettle();

    // Verify that dogs are displayed.
    expect(find.byType(ListTile), findsWidgets);

    // Tap on the first dog in the list.
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    // Verify that the dog details are displayed.
    expect(find.text('Like'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap the 'Like' button.
    await tester.tap(find.text('Like'));
    await tester.pumpAndSettle();

    // Navigate to the 'Liked Dogs' page.
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    // Verify that the liked dog is displayed.
    expect(find.byType(ListTile), findsOneWidget);
  });
}