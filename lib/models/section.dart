import 'grade_student.dart';

class Section {
  String name;
  List<GradeStudent> students;

  Section({required this.name, required this.students});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'students': students.map((student) => student.toJson()).toList(),
    };
  }

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      name: json['name'],
      students: List<GradeStudent>.from(
        json['students'].map((studentJson) => GradeStudent.fromJson(studentJson)),
      ),
    );
  }
}