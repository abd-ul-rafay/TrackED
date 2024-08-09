import 'package:tracked/models/section.dart';

class Grade {
  String name;
  List<Section> sections;

  Grade({required this.name, required this.sections});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      name: json['name'],
      sections: List<Section>.from(
        json['sections'].map((sectionJson) => Section.fromJson(sectionJson)),
      ),
    );
  }
}