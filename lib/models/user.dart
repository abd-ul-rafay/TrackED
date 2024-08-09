import 'package:tracked/models/Student.dart';
import 'package:tracked/models/subject.dart';
import 'group.dart';

class User {
  String name;
  String pin;
  String role; // admin, teacher, guard
  String gender;
  String major;
  String schoolName;
  String schoolAbbr;
  String schoolID;
  String schoolAddress;
  List<Subject> subjects;
  List<Student> studentsReport;
  List<Group> groups;

  User({
    required this.name,
    required this.pin,
    required this.role,
    required this.gender,
    required this.major,
    required this.schoolName,
    required this.schoolAbbr,
    required this.schoolID,
    required this.schoolAddress,
    required this.subjects,
    required this.studentsReport,
    required this.groups });

  Map<String, dynamic> toJson() {

    return {
      'name': name,
      'pin': pin,
      'role': role,
      'gender': gender,
      'major': major,
      'schoolName': schoolName,
      'schoolAbbr': schoolAbbr,
      'schoolID': schoolID,
      'schoolAddress': schoolAddress,
      'subjects': subjects.map((subject) => subject.toJson()).toList(),
      'studentsReport': studentsReport.map((student) => student.toJson()).toList(),
      'groups': groups.map((group) => group.toJson()).toList(),
    };
  }

  static User fromJson(Map<String, dynamic>? json) => User(
    name: json!['name'] ?? '',
    pin: json['pin'] ?? '',
    role: json['role'] ?? '',
    gender: json['gender'] ?? '',
    major: json['major'] ?? '',
    schoolName: json['schoolName'] ?? '',
    schoolAbbr: json['schoolAbbr'] ?? '',
    schoolID: json['schoolID'] ?? '',
    schoolAddress: json['schoolAddress'] ?? '',
    subjects: json['subjects'] == null? [] : (json['subjects'] as List<dynamic>).whereType<Map<String, dynamic>>().map((s) => Subject.fromJson(s)).toList(),
    studentsReport: json['studentsReport'] == null? [] : (json['studentsReport'] as List<dynamic>).whereType<Map<String, dynamic>>().map((s) => Student.fromJson(s)).toList(),
    groups: json['groups'] == null? [] : (json['groups'] as List<dynamic>).whereType<Map<String, dynamic>>().map((g) => Group.fromJson(g)).toList(),
  );
}
