// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:richfieldlost/main.dart';

void main() {
  testWidgets('Lost & Found app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LostFoundApp());

    // Wait for initial frame
    await tester.pump();

    // Verify that the splash screen is displayed
    expect(find.text('RICHFIELD'), findsOneWidget);
    expect(find.text('GRADUATE INSTITUTE OF TECHNOLOGY'), findsOneWidget);
    expect(find.text('Lost & Found'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
  });
}
