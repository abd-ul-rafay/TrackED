import 'package:flutter/material.dart';
import '../../models/grade.dart';
import '../../services/grade_manager.dart';
import 'manage_section.dart';

class MyGrades extends StatefulWidget {
  const MyGrades({Key? key}) : super(key: key);

  @override
  State<MyGrades> createState() => _MyGradesState();
}

class _MyGradesState extends State<MyGrades> {
  GradeStorage gradeStorage = GradeStorage();
  List<Grade> grades = [];
  bool gradeListLoaded = false;

  @override
  void initState() {
    super.initState();
    loadGrades();
  }

  void loadGrades() async {
    List<Grade> loadedGrades = await gradeStorage.getGrades();
    setState(() {
      grades = loadedGrades;
      gradeListLoaded = true;
    });
  }

  void addGrade() async {
    final nameTextController = TextEditingController();

    // using two times
    void add() async {
      if (nameTextController.text.trim().isEmpty) {
        Navigator.pop(context);
        return;
      }

      Navigator.pop(context);

      await gradeStorage.addGrade(Grade(name: nameTextController.text.trim(), sections: []));
      loadGrades();
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Grade:', style: TextStyle(fontWeight: FontWeight.bold),),
          TextField(
            controller: nameTextController,
            textInputAction: TextInputAction.done,
            onEditingComplete: add,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: ()=> Navigator.pop(context),
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: add,
            child: const Text('Add',)
        ),
      ],
    ),);
  }

  void removeGrade(Grade grade) async {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Are you sure, you want to delete this Grade?', style: TextStyle(fontSize: 16.0,),),
      actions: [
        TextButton(
            onPressed: ()=> Navigator.pop(context),
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await gradeStorage.removeGrade(grade);
              loadGrades();
            },
            child: const Text('Delete',)
        ),
      ],
    ),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grades'),
        actions: [
          IconButton(
            onPressed: addGrade,
            icon: const Icon(Icons.add),),
        ],
      ),
      body: gradeListLoaded && grades.isEmpty
        ? const Center(child: Text('Press + icon to add Grade'),)
        : ListView.builder(
        itemCount: grades.length,
        itemBuilder: (context, index) {
          Grade grade = grades[index];
          return Padding (
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: GestureDetector(
              onTap: ()=> Navigator.of(context).push(MaterialPageRoute(builder: (context) => ManageSection(grade: grade,),),),
              child: Card(
                child: ListTile(
                  title: Text(grade.name),
                  subtitle: Text('Sections: ${grade.sections.length}'),
                  trailing: IconButton(
                    onPressed: ()=> removeGrade(grade),
                    icon: const Icon(Icons.delete),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
