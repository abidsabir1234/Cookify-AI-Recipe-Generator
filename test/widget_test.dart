// Basic Flutter widget test for Recipe Genius app.

import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_app/main.dart';

void main() {
  testWidgets('RecipeAIApp builds successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RecipeAIApp());

    // Verify that the app title is rendered.
    expect(find.text('Recipe Genius'), findsOneWidget);
  });
}
