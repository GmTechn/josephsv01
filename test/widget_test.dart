import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:josephs_vs_01/main.dart';
import 'package:josephs_vs_01/pages/homepage.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(initialTheme: 'original', firstPage: HomePage()),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
