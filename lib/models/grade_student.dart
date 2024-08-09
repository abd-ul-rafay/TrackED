class GradeStudent {
  String lrn;
  String name;
  String gender;
  String phNumber;

  GradeStudent({required this.lrn, required this.name, required this.gender, required this.phNumber});

  Map<String, dynamic> toJson() {
    return {
      'lrn': lrn,
      'name': name,
      'gender': gender,
      'phNumber': phNumber
    };
  }

  factory GradeStudent.fromJson(Map<String, dynamic> json) {
    return GradeStudent(
      lrn: json['lrn'],
      name: json['name'],
      gender: json['gender'],
      phNumber: json['phNumber']
    );
  }
}
