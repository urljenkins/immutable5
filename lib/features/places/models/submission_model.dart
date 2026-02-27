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
      id: json['id'],
      name: json['name'],
      category: json['category'],
      lat: json['lat'],
      lng: json['lng'],
      wuduAvailable: json['wuduAvailable'] ?? false,
      womenSpaceAvailable: json['womenSpaceAvailable'] ?? false,
      description: json['description'],
      submittedBy: json['submittedBy'],
      submissionDate: DateTime.parse(json['submissionDate']),
      status: json['status'],
    );
  }
}
