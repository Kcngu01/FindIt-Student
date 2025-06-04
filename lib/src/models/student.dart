class Student{
  final String name;
  final String email;
  final int id;
  final int matricNo;
  final bool? emailVerified;

  Student({
    required this.name, 
    required this.email, 
    required this.id, 
    required this.matricNo, 
    this.emailVerified
  });

  factory Student.fromJson(Map<String,dynamic> json){
    // Check if we have a nested user object
    final userData = json.containsKey('user') ? json['user'] : json;
    
    // Handle matric_no field name difference between API (matric_no) and Flutter model (matricNo)
    int matricNumber;
    if (userData.containsKey('matricNo')) {
      matricNumber = userData['matricNo'] ?? 0;
    } else if (userData.containsKey('matric_no')) {
      matricNumber = userData['matric_no'] ?? 0;
    } else {
      matricNumber = 0; // Default value if neither key exists
    }
    
    return Student(
      name: userData['name'] ?? '',
      email: userData['email'] ?? '',
      id: userData['id'] ?? 0,
      matricNo: matricNumber,
      emailVerified: userData['email_verified'] == 1 || userData['email_verified'] == true,
    );
  }
}