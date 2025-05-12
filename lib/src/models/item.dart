class Item {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final String type;
  final String status;
  final int categoryId;
  final int colorId;
  final int locationId;
  final int studentId;
  final String createdAt;
  final String updatedAt;

  Item({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.type,
    required this.status,
    required this.categoryId,
    required this.colorId,
    required this.locationId,
    required this.studentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      type: json['type'],
      status: json['status'],
      categoryId: json['category_id'],
      colorId: json['color_id'],
      locationId: json['location_id'],
      studentId: json['student_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}