class StudentNotification {
  final int id;
  final int studentId;
  final String title;
  final String body;
  final String? type;
  final dynamic data;
  final String status;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  StudentNotification({
    required this.id,
    required this.studentId,
    required this.title,
    required this.body,
    this.type,
    this.data,
    required this.status,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentNotification.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse DateTime
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        if (value is String) {
          return DateTime.parse(value);
        }
      } catch (e) {
        print('Error parsing date: $value, Error: $e');
      }
      return null;
    }

    // Handle potentially missing or null values 
    return StudentNotification(
      id: json['id'] ?? 0,
      studentId: json['student_id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'],
      data: json['data'], // Can be map, string, or null
      status: json['status'] ?? 'unread',
      readAt: parseDateTime(json['read_at']),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'status': status,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 