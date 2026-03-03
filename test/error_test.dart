import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/di/service_locator.dart';
import 'package:immutable5/features/places/places_page.dart';
import 'package:immutable5/l10n/app_localizations.dart';

void main() {
  testWidgets('Catch all errors', (WidgetTester tester) async {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('CAUGHT EXCEPTION:\n\${details.exception}');
    };

    setupLocator();
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlacesPage(),
      ),
    );
    await tester.pumpAndSettle();
  });
}
