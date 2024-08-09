
class Group {
  String name;
  Map<String, String> phoneNumbers;

  Group({required this.name, required this.phoneNumbers});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumbers': phoneNumbers,
    };
  }

  static Group fromJson(Map<String, dynamic> json) => Group(
      name: json['name'] as String,
      phoneNumbers: json['phoneNumbers'] == null? {} : Map<String, String>.from(json['phoneNumbers'] as Map),
  );

}
