// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wish_listy/main.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Create a mock localization service
    final localizationService = LocalizationService();
    await localizationService.initialize();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MyApp(
        localizationService: localizationService,
        authRepository: AuthRepository(),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
