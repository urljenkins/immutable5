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

    String type = 'other';
    String subcategory = 'other';

    if (tags['amenity'] == 'place_of_worship' && tags['religion'] == 'muslim') {
      type = 'mosque';
      subcategory = 'masjid';
    } else if (tags['amenity'] == 'prayer_room' || tags['room'] == 'prayer') {
      type = 'formal';
      subcategory = 'prayer_room';
    } else if (tags['leisure'] == 'park' || tags['leisure'] == 'garden') {
      type = 'outdoor';
      subcategory = 'park';
    } else if (tags['amenity'] == 'university' ||
        tags['amenity'] == 'hospital' ||
        tags['amenity'] == 'airport') {
      type = 'informal';
      subcategory = 'quiet_room';
    }

    return PlaceModel(
      id: json['id'].toString(),
      name: (tags['name'] as String?) ??
          (tags['name:en'] as String?) ??
          'Prayer Place',
      type: type,
      subcategory: subcategory,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lon'] as num).toDouble(),
      verified: true,
      details: tags,
    );
  }
}
