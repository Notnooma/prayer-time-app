// Basic Flutter widget test for Prayer Times App.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wia_prayer_app/main.dart';

void main() {
  testWidgets('Prayer Times App loads properly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Wait for the app to finish loading
    await tester.pumpAndSettle();

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify app title is present
    expect(find.text('WIA Prayer Times'), findsOneWidget);
  });
}
