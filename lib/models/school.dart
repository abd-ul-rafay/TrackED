
class School {
  String name;
  String abbreviation;
  String id;
  String address;
  List schoolUsersRef; // reference to firebase uid

  School({
    required this.name,
    required this.abbreviation,
    required this.id,
    required this.address,
    required this.schoolUsersRef
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'id': id,
      'address': address,
      'schoolUsersRef': schoolUsersRef
    };
  }

  static School fromJson(Map<String, dynamic>? json) => School(
    name: json!['name'] ?? '',
    abbreviation: json['abbreviation'] ?? '',
    id: json['id'] ?? '',
    address: json['address'] ?? '',
    schoolUsersRef: json['schoolUsersRef'] ?? [],
  );
}
