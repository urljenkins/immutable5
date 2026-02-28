import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:immutable5/features/places/places_page.dart';
import 'package:immutable5/di/service_locator.dart';
import 'package:immutable5/l10n/app_localizations.dart';

void main() {
  testWidgets('Check PlacesPage map dimensions', (WidgetTester tester) async {
    setupLocator();
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const PlacesPage(),
    ));
    await tester.pumpAndSettle();

    final mapFinder = find.byType(FlutterMap);
    final size = tester.getSize(mapFinder);
    print('FLUTTERMAP SIZE: $size');
  });
}
