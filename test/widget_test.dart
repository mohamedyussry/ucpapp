// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/language_selection_screen.dart';

void main() {
  testWidgets('LanguageSelectionScreen has expected content', (WidgetTester tester) async {
    // Build the LanguageSelectionScreen directly.
    // We wrap it in a MaterialApp to provide the necessary context (like theme, navigation, etc.)
    await tester.pumpWidget(
      const MaterialApp(
        home: LanguageSelectionScreen(),
      ),
    );

    // Verify that the language selection screen is shown and has the correct text.
    expect(find.text('Choose Language'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);

    // Verify the initial selection is English
    final englishButton = tester.widget<GestureDetector>(find.ancestor(of: find.text('English'), matching: find.byType(GestureDetector)));
    final englishContainer = englishButton.child as Container;
    final englishDecoration = englishContainer.decoration as BoxDecoration;
    expect(englishDecoration.border, isA<Border>().having((b) => b.top.color, 'color', Colors.orange));

    // Tap on 'العربية' and verify the selection changes
    await tester.tap(find.text('العربية'));
    await tester.pump();

    final arabicButton = tester.widget<GestureDetector>(find.ancestor(of: find.text('العربية'), matching: find.byType(GestureDetector)));
    final arabicContainer = arabicButton.child as Container;
    final arabicDecoration = arabicContainer.decoration as BoxDecoration;
    expect(arabicDecoration.border, isA<Border>().having((b) => b.top.color, 'color', Colors.orange));
  });
}
