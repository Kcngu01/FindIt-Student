//model for claims by item potential matches ( in tab 'my claims' under my_item_details_screen)
class ClaimByMatch{
  final int id;
  final String name;
  final String description;
  final String type;
  final String color;
  final String location;
  final String category;
  final String image;
  final String foundItemDate;
  final String adminName;
  final String email;
  final String adminJustification;
  final String studentJustification;
  final String similarityScore;
  final String createdAt;
  final String status;
  final String reporterEmail;

  ClaimByMatch({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.color,
    required this.location,
    required this.category,
    required this.image,
    required this.foundItemDate,
    required this.adminName,
    required this.email,
    required this.adminJustification,
    required this.studentJustification,
    required this.similarityScore,
    required this.createdAt,
    required this.status,
    required this.reporterEmail,
  });

  factory ClaimByMatch.fromJson(Map<String, dynamic> json) {
    return ClaimByMatch(
      id: json['id'] ?? 0,
      
      // Item details
      name: json['found_item']?['name'] ?? 'Unnamed Item',
      description: json['found_item']?['description'] ?? '-',
      type: json['found_item']?['type'] ?? 'unknown',
      image: json['found_item']?['image'] ?? '',
      foundItemDate: json['found_item']?['created_at'] ?? '-',
      reporterEmail: json['found_item']?['student']?['email'] ?? '-',
      
      // Item characteristics
      color: json['found_item']?['color']?['name'] ?? 'Unknown Color',
      location: json['found_item']?['location']?['name'] ?? 'Unknown Location',
      category: json['found_item']?['category']?['name'] ?? 'Unknown Category',
      
      // Admin information
      adminName: json['admin']?['name'] ?? 'Unknown Admin',
      email: json['admin']?['email'] ?? '-',
      
      // Claim details
      adminJustification: json['admin_justification'] ?? '-',
      studentJustification: json['student_justification'] ?? '-',
      createdAt: json['created_at'] ?? DateTime.now().toString(),
      status: json['status'] ?? 'pending',
      similarityScore: (json['match']['similarity_score'] is num ? '${(json['match']['similarity_score'] * 100).toStringAsFixed(2)}%' : json['match']['similarity_score'].toString()),



    );
  }
}

