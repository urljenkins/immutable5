import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/place_model.dart';
import '../models/submission_model.dart';

class PlacesService {
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  static const String _osrmUrl = 'http://router.project-osrm.org/route/v1/driving';

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

  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    try {
      final url = Uri.parse(
          '$_osrmUrl/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          return coordinates.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
        }
      }
      return [];
    } catch (e) {
      developer.log('Error fetching route: $e');
      return [];
    }
  }

  Future<List<PlaceModel>> getNearbyPlaces(double lat, double lng,
      {double radius = 5000,}) async {
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
