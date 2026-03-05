import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/di/service_locator.dart';
import 'package:immutable5/features/places/places_page.dart';
import 'package:immutable5/features/places/services/places_service.dart';
import 'package:immutable5/l10n/app_localizations.dart';

void main() {
  testWidgets('Catch all errors', (WidgetTester tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('CAUGHT EXCEPTION:\n${details.exception}');
    };

    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    if (!getIt.isRegistered<PlacesService>()) {
      setupLocator();
    }

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
    await tester.pump(const Duration(seconds: 1));
  });
}
