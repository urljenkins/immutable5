import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../models/submission_model.dart';
import 'dart:developer' as developer;

class PlacesService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';

  // Local cache for pending submissions (simulating backend)
  final List<SubmissionModel> _pendingSubmissions = [];

  Future<void> submitPlace(SubmissionModel submission) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    _pendingSubmissions.add(submission);
  }

  Future<List<SubmissionModel>> getPendingPlaces() async {
    return _pendingSubmissions;
  }

  Future<List<PlaceModel>> getNearbyPlaces(double lat, double lng,
      {double radius = 5000}) async {
    // Overpass QL query: find nodes/ways with amenity=place_of_worship and religion=muslim within radius
    final query = '''
      [out:json][timeout:25];
      (
        node["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
        way["amenity"="place_of_worship"]["religion"="muslim"](around:$radius,$lat,$lng);
      );
      out center;
    ''';

    try {
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements =
            (data['elements'] as List).cast<Map<String, dynamic>>();

        return elements.map((e) {
          if (e['type'] == 'way' && e.containsKey('center')) {
            return PlaceModel.fromJson({
              ...e,
              'lat': e['center']['lat'],
              'lon': e['center']['lon'],
            });
          }
          return PlaceModel.fromJson(e);
        }).toList();
      } else {
        developer.log('Failed to fetch places: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      developer.log('Error fetching places: $e');
      return [];
    }
  }
}
