import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/grade.dart';
import '../models/grade_student.dart';
import '../models/section.dart';

class GradeStorage {
  static const String gradesKey = 'grades';

  Future<List<Grade>> getGrades() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? gradesJson = prefs.getString(gradesKey);
    if (gradesJson != null) {
      List<dynamic> gradesData = jsonDecode(gradesJson);
      return gradesData.map((gradeJson) => Grade.fromJson(gradeJson)).toList();
    } else {
      return [];
    }
  }

  Future<void> saveGrades(List<Grade> grades) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<dynamic> gradesData = grades.map((grade) => grade.toJson()).toList();
    String gradesJson = jsonEncode(gradesData);
    await prefs.setString(gradesKey, gradesJson);
  }

  Future<void> addGrade(Grade newGrade) async {
    List<Grade> grades = await getGrades();
    grades.add(newGrade);
    await saveGrades(grades);
  }

  Future<void> removeGrade(Grade gradeToRemove) async {
    List<Grade> grades = await getGrades();
    grades.removeWhere((grade) => grade.name == gradeToRemove.name && grade.sections.length == gradeToRemove.sections.length);
    await saveGrades(grades);
  }

  Future<void> editGrade(Grade editedGrade) async {
    List<Grade> grades = await getGrades();
    int index = grades.indexWhere((grade) => grade.name == editedGrade.name);
    if (index != -1) {
      grades[index] = editedGrade;
      await saveGrades(grades);
    }
  }

  Future<void> addSection(Grade grade, Section newSection) async {
    int gradeIndex = await findGradeIndex(grade.name);
    if (gradeIndex != -1) {
      List<Grade> grades = await getGrades();
      grades[gradeIndex].sections.add(newSection);
      await saveGrades(grades);
    }
  }

  Future<void> removeSection(Grade grade, Section sectionToRemove) async {
    int gradeIndex = await findGradeIndex(grade.name);
    if (gradeIndex != -1) {
      List<Grade> grades = await getGrades();
      int sectionIndex = grades[gradeIndex].sections
          .indexWhere((section) => section.name == sectionToRemove.name);
      if (sectionIndex != -1) {
        grades[gradeIndex].sections.removeAt(sectionIndex);
        await saveGrades(grades);
      }
    }
  }

  Future<void> editSection(Grade grade, Section editedSection) async {
    int gradeIndex = await findGradeIndex(grade.name);
    if (gradeIndex != -1) {
      List<Grade> grades = await getGrades();
      int sectionIndex = grades[gradeIndex].sections
          .indexWhere((section) => section.name == editedSection.name);
      if (sectionIndex != -1) {
        grades[gradeIndex].sections[sectionIndex] = editedSection;
        await saveGrades(grades);
      }
    }
  }

  Future<void> addStudent(Grade grade, Section section, GradeStudent newStudent) async {
    int gradeIndex = await findGradeIndex(grade.name);
    if (gradeIndex != -1) {
      List<Grade> grades = await getGrades();
      int sectionIndex = grades[gradeIndex].sections
          .indexWhere((s) => s.name == section.name);
      if (sectionIndex != -1) {
        grades[gradeIndex].sections[sectionIndex].students.add(newStudent);
        await saveGrades(grades);
      }
    }
  }

  Future<void> removeStudent(Grade grade, Section section, GradeStudent studentToRemove) async {
    int gradeIndex = await findGradeIndex(grade.name);
    if (gradeIndex != -1) {
      List<Grade> grades = await getGrades();
      int sectionIndex = grades[gradeIndex].sections
          .indexWhere((s) => s.name == section.name);
      if (sectionIndex != -1) {
        int studentIndex = grades[gradeIndex].sections[sectionIndex].students
            .indexWhere((student) => student.name == studentToRemove.name);
        if (studentIndex != -1) {
          grades[gradeIndex].sections[sectionIndex].students.removeAt(studentIndex);
          await saveGrades(grades);
        }
      }
    }
  }

  Future<void> editStudent(
      Grade grade, Section section, GradeStudent editedStudent) async {
    int gradeIndex = await findGradeIndex(grade.name);
    if (gradeIndex != -1) {
      List<Grade> grades = await getGrades();
      int sectionIndex = grades[gradeIndex].sections
          .indexWhere((s) => s.name == section.name);
      if (sectionIndex != -1) {
        int studentIndex = grades[gradeIndex].sections[sectionIndex].students
            .indexWhere((student) => student.lrn == editedStudent.lrn);
        if (studentIndex != -1) {
          grades[gradeIndex].sections[sectionIndex].students[studentIndex].name =
              editedStudent.name;
          grades[gradeIndex].sections[sectionIndex].students[studentIndex].gender =
              editedStudent.gender;
          grades[gradeIndex].sections[sectionIndex].students[studentIndex].phNumber =
              editedStudent.phNumber;
          await saveGrades(grades);
        }
      }
    }
  }

  Future<Section?> findSection(String gradeName, String sectionName) async {
    int gradeIndex = await findGradeIndex(gradeName);
    if (gradeIndex != -1) {
      List<Grade> grades = await getGrades();
      Grade grade = grades[gradeIndex];
      int sectionIndex =
      grade.sections.indexWhere((section) => section.name == sectionName);
      if (sectionIndex != -1) {
        return grade.sections[sectionIndex];
      }
    }
    return null;
  }

  Future<int> findGradeIndex(String gradeName) async {
    List<Grade> grades = await getGrades();
    return grades.indexWhere((grade) => grade.name == gradeName);
  }
}
