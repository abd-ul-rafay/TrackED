import 'package:flutter/material.dart';
import '../../models/grade.dart';
import '../../models/section.dart';
import '../../services/grade_manager.dart';
import 'manage_students.dart';

class ManageSection extends StatefulWidget {
  final Grade grade;
  const ManageSection({Key? key, required this.grade}) : super(key: key);

  @override
  State<ManageSection> createState() => _ManageSectionState();
}

class _ManageSectionState extends State<ManageSection> {
  GradeStorage gradeStorage = GradeStorage();

  void addSection() {
    final nameTextController = TextEditingController();

    // using two times
    void add() async {
      if (nameTextController.text.trim().isEmpty) {
        Navigator.pop(context);
        return;
      }

      await gradeStorage.addSection(widget.grade, Section(name: nameTextController.text.trim(), students: []));
      widget.grade.sections.add(Section(name: nameTextController.text.trim(), students: []));
      setState(() {});
      Navigator.pop(context);
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Section:', style: TextStyle(fontWeight: FontWeight.bold),),
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

  void removeSection(Section section) async {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Are you sure, you want to delete this Section?', style: TextStyle(fontSize: 16.0,),),
      actions: [
        TextButton(
            onPressed: ()=> Navigator.pop(context),
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await gradeStorage.removeSection(widget.grade, section);
              widget.grade.sections.remove(section);
              setState(() {});
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
        title: Text(widget.grade.name),
        actions: [
          IconButton(
            onPressed: addSection,
            icon: const Icon(Icons.add),),
        ],
      ),
      body: widget.grade.sections.isEmpty
        ? const Center(child: Text('Press + icon to add Section'),)
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text('List of Sections:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,),
            ),
          ),
            Expanded(
              child: ListView.builder(
              itemCount: widget.grade.sections.length,
              itemBuilder: (context, index) {
                Section section = widget.grade.sections[index];
                final males = section.students.where((s) => s.gender == 'M').toList().length;
                final females = section.students.where((s) => s.gender == 'F').toList().length;
                return Padding (
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: GestureDetector(
                    onTap: ()=> Navigator.of(context).push(MaterialPageRoute(builder: (context) => ManageStudents(section: section, grade: widget.grade,),),),
                    child: Card(
                      child: ListTile(
                        title: Text(section.name),
                        subtitle: Text('Males: $males | Females: $females | Total: ${males + females}'),
                        trailing: IconButton(
                          onPressed: ()=> removeSection(section),
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
