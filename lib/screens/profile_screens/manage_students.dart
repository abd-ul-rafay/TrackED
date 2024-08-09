import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracked/models/student.dart';
import 'package:tracked/screens/profile_screens/input_student_data.dart';
import '../../models/grade.dart';
import '../../models/grade_student.dart';
import '../../models/section.dart';
import '../../services/grade_manager.dart';
import 'edit_student.dart';

class ManageStudents extends StatefulWidget {
  final Grade grade;
  final Section section;
  const ManageStudents({Key? key, required this.section, required this.grade}) : super(key: key);

  @override
  State<ManageStudents> createState() => _ManageStudentsState();
}

class _ManageStudentsState extends State<ManageStudents> {
  GradeStorage gradeStorage = GradeStorage();

  void removeStudent(GradeStudent student) async {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Are you sure, you want to delete this Student?', style: TextStyle(fontSize: 16.0,),),
      actions: [
        TextButton(
            onPressed: ()=> Navigator.pop(context),
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await gradeStorage.removeStudent(widget.grade, widget.section, student);
              widget.section.students.remove(student);
              setState(() {});
            },
            child: const Text('Delete',)
        ),
      ],
    ),);
  }

  Future<File?> retrieveImage(String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/$name.jpg';
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    } else {
      return null;
    }
  }

  void goForEditing(GradeStudent student) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditStudent(grade: widget.grade, section: widget.section, student: student,),),)
        .then((value) async {
      Section? section = await gradeStorage.findSection(widget.grade.name, widget.section.name);
      if (section != null) {
        widget.section.students = section.students;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final males = widget.section.students.where((s) => s.gender == 'M').toList();
    final females = widget.section.students.where((s) => s.gender == 'F').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.name),
        actions: [
          IconButton(
            onPressed: ()=> Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => InputStudentData(grade: widget.grade, section: widget.section,),),
            ).then((value) async {
              Section? section = await gradeStorage.findSection(widget.grade.name, widget.section.name);
              if (section != null) {
                widget.section.students = section.students;
                setState(() {});
              }
            }),
            icon: const Icon(Icons.add),),
        ],
      ),
      body: widget.section.students.isEmpty
        ? const Center(child: Text('Press + icon to add Student'),)
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text('List of Students:',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text('Male:',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold,),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: males.length,
                itemBuilder: (context, index) {
                  GradeStudent student = males[index];
                  return Padding (
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: GestureDetector(
                      onTap:()=> goForEditing(student),
                      child: Card(
                        child: ListTile(
                          leading: FutureBuilder<File?>(
                            future: retrieveImage(student.name),
                            builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                // While the image is being retrieved, you can show a placeholder or a loading indicator.
                                return const CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, color: Colors.black),
                                  // Placeholder or loading indicator
                                );
                              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                // Handle the case where the image is not available
                                return const CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, color: Colors.black),
                                  // Placeholder or fallback widget
                                );
                              } else {
                                final imageFile = snapshot.data!;
                                return CircleAvatar(
                                  backgroundImage: FileImage(imageFile),
                                  backgroundColor: Colors.grey,
                                );
                              }
                            },
                          ),
                          title: Text(student.name),
                          // subtitle: Text('LRN: ${student.lrn}'),
                          trailing: IconButton(
                            onPressed: ()=> removeStudent(student),
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Text('Female:',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold,),
              ),
            ),
            Expanded(
              child: ListView.builder(
              itemCount: females.length,
              itemBuilder: (context, index) {
                GradeStudent student = females[index];
                return Padding (
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: ()=> goForEditing(student),
                    child: Card(
                      child: ListTile(
                        leading: FutureBuilder<File?>(
                          future: retrieveImage(student.name),
                          builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              // While the image is being retrieved, you can show a placeholder or a loading indicator.
                              return const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.black),
                                // Placeholder or loading indicator
                              );
                            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                              // Handle the case where the image is not available
                              return const CircleAvatar(
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.black),
                                // Placeholder or fallback widget
                              );
                            } else {
                              final imageFile = snapshot.data!;
                              return CircleAvatar(
                                backgroundImage: FileImage(imageFile),
                                backgroundColor: Colors.grey,
                              );
                            }
                          },
                        ),
                        title: Text(student.name),
                        // subtitle: Text('LRN: ${student.lrn}'),
                        trailing: IconButton(
                          onPressed: ()=> removeStudent(student),
                          icon: const Icon(Icons.delete),
                        ),
                      ),
                    ),
                  ),
                );
              },
      ),
            ),
          ],
        ),
    );
  }
}
