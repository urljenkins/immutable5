class SubmissionModel {
  final String id;
  final String name;
  final String category; // Mosque, Quiet Room, Workplace, etc.
  final double lat;
  final double lng;
  final bool wuduAvailable;
  final bool womenSpaceAvailable;
  final String? description;
  final String submittedBy;
  final DateTime submissionDate;
  final String status; // pending, verified, rejected

  SubmissionModel({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    this.wuduAvailable = false,
    this.womenSpaceAvailable = false,
    this.description,
    required this.submittedBy,
    required this.submissionDate,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'lat': lat,
      'lng': lng,
      'wuduAvailable': wuduAvailable,
      'womenSpaceAvailable': womenSpaceAvailable,
      'description': description,
      'submittedBy': submittedBy,
      'submissionDate': submissionDate.toIso8601String(),
      'status': status,
    };
  }

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      wuduAvailable: (json['wuduAvailable'] as bool?) ?? false,
      womenSpaceAvailable: (json['womenSpaceAvailable'] as bool?) ?? false,
      description: json['description'] as String?,
      submittedBy: json['submittedBy'] as String,
      submissionDate: DateTime.parse(json['submissionDate'] as String),
      status: json['status'] as String,
    );
  }
}
