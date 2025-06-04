//similar to claim model, but dont have 'similarityScore' attribute
class Claim{
  final int id;
  final String name;
  final String description;
  final String type;
  final String color;
  final String location;
  final String category;
  final String image;
  final String foundItemDate;
  final String adminId;
  final String adminName;
  final String email;
  final String adminJustification;
  final String studentJustification;
  final String createdAt;
  final String status;
  final String claimLocation;

  Claim({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.color,
    required this.location,
    required this.category,
    required this.image,
    required this.foundItemDate,
    required this.adminId,
    required this.adminName,
    required this.email,
    required this.adminJustification,
    required this.studentJustification,
    required this.createdAt,
    required this.status,
    this.claimLocation = '',
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] ?? 0,
      
      // Item details
      name: json['found_item']?['name'] ?? 'Unnamed Item',
      description: json['found_item']?['description'] ?? '-',
      type: json['found_item']?['type'] ?? 'unknown',
      image: json['found_item']?['image'] ?? '',
      foundItemDate: json['found_item']?['created_at'] ?? '-',
      
      // Item characteristics
      color: json['found_item']?['color']?['name'] ?? 'Unknown Color',
      location: json['found_item']?['location']?['name'] ?? 'Unknown Location',
      category: json['found_item']?['category']?['name'] ?? 'Unknown Category',
      claimLocation: json['found_item']?['claim_location']?['name'] ?? '',
      
      // Admin information
      adminId: json['admin_id']?.toString() ?? '0',
      adminName: json['admin']?['name'] ?? 'Unknown Admin',
      email: json['admin']?['email'] ?? '-',
      
      // Claim details
      adminJustification: json['admin_justification'] ?? '-',
      studentJustification: json['student_justification'] ?? '-',
      createdAt: json['created_at'] ?? DateTime.now().toString(),
      status: json['status'] ?? 'pending'
    );
  }
}