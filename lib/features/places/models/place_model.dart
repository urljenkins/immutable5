class PlaceModel {
  final String id;
  final String name;
  final String type;
  final String? subcategory;
  final double lat;
  final double lng;
  final bool verified;
  final Map<String, dynamic>? details;

  const PlaceModel({
    required this.id,
    required this.name,
    required this.type,
    this.subcategory,
    required this.lat,
    required this.lng,
    this.verified = false,
    this.details,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final tags = json['tags'] as Map<String, dynamic>? ?? {};

    return PlaceModel(
      id: json['id'].toString(),
      name: tags['name'] ?? tags['name:en'] ?? 'Prayer Place',
      type: tags['amenity'] == 'place_of_worship' ? 'mosque' : 'other',
      subcategory: tags['religion'] == 'muslim' ? 'mosque' : tags['amenity'],
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lon'] as num).toDouble(),
      verified: true, // Assuming OSM data is "verified" for now
      details: tags,
    );
  }
}
