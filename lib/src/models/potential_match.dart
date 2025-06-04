//similar to item model, and have one more different attributes 'similarityScore'
class PotentialMatch {
  final int id;
  final int foundItemId;
  final String name;
  final String? description;
  final String? image;
  final String type;
  final String status;
  final String matchStatus;
  final String category;
  final String color;
  final String location;
  final String createdAt;
  final String similarityScore;
  final String email;

  PotentialMatch({
    required this.id,
    required this.foundItemId,
    required this.name,
    this.description,
    this.image,
    required this.type,
    required this.status,
    required this.matchStatus,
    required this.category,
    required this.color,
    required this.location,
    required this.createdAt,
    required this.similarityScore,
    required this.email,
  });

  factory PotentialMatch.fromJson(Map<String, dynamic> json) {
    return PotentialMatch(
      id: json['id'],
      foundItemId: json['found_item']?['id']??0,
      name: json['found_item']?['name'],
      description: json['found_item']?['description']??'-',
      image: json['found_item']?['image']??'',
      type: json['found_item']?['type']??'unknown',
      status: json['found_item']?['status']??'unknown',
      matchStatus: json['status']??'unknown',
      category: json['found_item']?['category']?['name']??'unknown',
      color: json['found_item']?['color']?['name']??'unknown',
      location: json['found_item']?['location']?['name']??'unknown',
      createdAt: json['found_item']?['created_at']??'-',
      similarityScore: (json['similarity_score'] is num ? '${(json['similarity_score'] * 100).toStringAsFixed(2)}%' : json['similarity_score'].toString()),
      email: json['found_item']?['student']?['email']??'-',
    );
  }
}