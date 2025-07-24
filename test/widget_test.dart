// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:odtrack_academia/core/app.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ODTrackApp(),
      ),
    );

    // Verify that login screen loads
    expect(find.text('ODTrack Academia™'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
  });
}
