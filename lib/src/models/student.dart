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
    
    return Student(
      name: userData['name'],
      email: userData['email'],
      id: userData['id'],
      matricNo: userData['matricNo'],
      emailVerified: userData['email_verified'] == 1 || userData['email_verified'] == true,
    );
  }
}