class Student {
  String name;
  String lrn;
  String gradeSection;
  String subject;
  String phoneNo;
  DateTime date;
  String gender;
  bool isIn; // else is Out

  Student({
    required this.name,
    required this.lrn,
    required this.gradeSection,
    required this.subject,
    required this.phoneNo,
    required this.date,
    required this.gender,
    required this.isIn});

  Map<String, dynamic> toJson() => {
    'name': name,
    'lrn': lrn,
    'gradeSection': gradeSection,
    'subject': subject,
    'phoneNo': phoneNo,
    'date': date,
    'gender': gender,
    'isIn': isIn,
  };

  static Student fromJson(Map<String, dynamic>? json) => Student(
      name: json!['name'] ?? '',
      lrn: json['lrn'] ?? '',
      gradeSection: json['gradeSection'] ?? '',
      subject: json['subject'] ?? '',
      phoneNo: json['phoneNo'] ?? '',
      date: json['date'].toDate(),
      gender: json['gender'] ?? '',
      isIn: json['isIn'] ?? '',
  );

  @override
  bool operator ==(other) {
    return other is Student && name == other.name;
  }

  @override
  int get hashCode => name.hashCode;
}
