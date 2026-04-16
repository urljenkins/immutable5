import 'package:flutter_test/flutter_test.dart';
import 'package:immutable5/features/places/models/submission_model.dart';
import 'package:immutable5/features/places/services/places_service.dart';

void main() {
  group('PlacesService', () {
    late PlacesService placesService;

    setUp(() {
      placesService = PlacesService();
    });

    test('submitPlace adds a submission to the pending list', () async {
      final submission = SubmissionModel(
        id: '1',
        name: 'Test Mosque',
        category: 'Mosque',
        lat: 21.3891,
        lng: 39.8579,
        submittedBy: 'test_user',
        submissionDate: DateTime.now(),
      );

      // We use a shorter timeout for tests if possible,
      // but the current implementation has a hardcoded 1s delay.
      await placesService.submitPlace(submission);

      final pendingPlaces = await placesService.getPendingPlaces();

      expect(pendingPlaces.length, 1);
      expect(pendingPlaces.first, submission);
      expect(pendingPlaces.first.name, 'Test Mosque');
    });

    test('getPendingPlaces returns an empty list initially', () async {
      final pendingPlaces = await placesService.getPendingPlaces();
      expect(pendingPlaces, isEmpty);
    });

    test('submitPlace handles multiple submissions', () async {
      final submission1 = SubmissionModel(
        id: '1',
        name: 'Mosque 1',
        category: 'Mosque',
        lat: 21.3891,
        lng: 39.8579,
        submittedBy: 'user1',
        submissionDate: DateTime.now(),
      );

      final submission2 = SubmissionModel(
        id: '2',
        name: 'Mosque 2',
        category: 'Mosque',
        lat: 21.4891,
        lng: 39.9579,
        submittedBy: 'user2',
        submissionDate: DateTime.now(),
      );

      await placesService.submitPlace(submission1);
      await placesService.submitPlace(submission2);

      final pendingPlaces = await placesService.getPendingPlaces();

      expect(pendingPlaces.length, 2);
      expect(pendingPlaces, contains(submission1));
      expect(pendingPlaces, contains(submission2));
    });
  });
}
