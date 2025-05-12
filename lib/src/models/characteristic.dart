class Characteristic{
  final int id;
  final String name;

  Characteristic({
    required this.id,
    required this.name,
  });

  factory Characteristic.fromJson(Map<String, dynamic> json) {
    return Characteristic(
      id: json['id'],
      name: json['name'],
    );
  }
}