import 'package:edu_share/screens/search_screen.dart';
import 'package:edu_share/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Search screen renders default state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.theme, home: const SearchScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Tim'), findsOneWidget);
    expect(find.textContaining('Goi y tim kiem'), findsOneWidget);
  });
}
