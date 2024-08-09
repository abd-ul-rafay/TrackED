import 'package:flutter/material.dart';
import '../../utils/consts.dart';
import '../../models/subject.dart';
import '../../models/user.dart' as model;
import '../../services/firestore.dart';

class MySubjectScreen extends StatefulWidget {
  final model.User user;
  const MySubjectScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<MySubjectScreen> createState() => _MySubjectScreenState();
}

class _MySubjectScreenState extends State<MySubjectScreen> {
  List<Subject> mySubjects = [];
  DateTime? fromDate; // for subjects
  DateTime? toDate; // for subjects

  void addSubject() {
    var nameTextController = TextEditingController();
    var noOfMaleTextController = TextEditingController();
    var noOfFemaleTextController = TextEditingController();
    var combinedTextController = TextEditingController(text: 'Combined: 0');
    var fromTimeTextController = TextEditingController(text: 'Select time');
    var toTimeTextController = TextEditingController(text: 'Select time');

    void add() { // we will// use it two times

      if (nameTextController.text.trim().toString().isEmpty
          || (noOfMaleTextController.text.trim().toString().isEmpty && noOfFemaleTextController.text.trim().toString().isEmpty)
      ) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields')));
        return;
      }

      if (fromDate == null || toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add from and to date')));
        return;
      }

      final subject = Subject(
        name: nameTextController.text.trim().toString(),
        noOfMale: noOfMaleTextController.text.trim().toString(),
        noOfFemale: noOfFemaleTextController.text.trim().toString(),
        fromTime: fromDate!,
        toTime: toDate!,
      );

      Navigator.pop(context);

      FirestoreService().addSubject(
        // after adding ot firebase, add to local list
          subject, () {
            setState(() {
              mySubjects.add(subject);
            });
          }
      );
    }

    void addToCombined() {
      if (noOfMaleTextController.text.trim().toString().isEmpty && noOfFemaleTextController.text.trim().toString().isEmpty) {
        combinedTextController.text = 'Combined: 0';
      } else if (noOfMaleTextController.text.trim().toString().isEmpty) {
        combinedTextController.text = 'Combined: ${noOfFemaleTextController.text.trim()}';
      } else if (noOfFemaleTextController.text.trim().toString().isEmpty) {
        combinedTextController.text = 'Combined: ${noOfMaleTextController.text.trim()}';
      } else {
        combinedTextController.text = 'Combined: ${int.parse(noOfMaleTextController.text.trim()) + int.parse(noOfFemaleTextController.text.trim())}';
      }
    }

    showDialog(context: context, builder: (context) => SimpleDialog(
        contentPadding: EdgeInsets.zero,
        children : [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Subject', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                  const SizedBox(height: 15.0,),
                  Row(
                    children: [
                      timeContainer(fromTimeTextController, 'From Time', true),
                      const SizedBox(width: 5.0,),
                      timeContainer(toTimeTextController, 'To Time', false),
                    ],
                  ),
                  TextField(
                    controller: nameTextController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Subject name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: noOfMaleTextController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      addToCombined();
                    },
                    decoration: const InputDecoration(
                      hintText: 'No. of Male',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: noOfFemaleTextController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      addToCombined();
                    },
                    decoration: const InputDecoration(
                      hintText: 'No. of Female',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: combinedTextController,
                    readOnly: true,
                    enabled: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 5.0,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: ()=> Navigator.pop(context),
                          child: const Text('Cancel')
                      ),
                      TextButton(
                          onPressed: add,
                          child: const Text('Add',)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ]
    ));
  }

  void removeSubject(List<Subject> subjects, int index) {

    showDialog(context: context, builder: (context) =>
        AlertDialog(
          icon: Icon(Icons.delete, color: myLightColor,),
          title: Text(
            'Are you sure you want remove ${subjects[index].name} subject?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  FirestoreService().removeSubject(
                    subjects[index], () {
                      setState(() {
                        subjects.removeAt(index);
                      });
                    } // after removing from firebase, remove from local list
                  );
                  Navigator.pop(context);
                },
                child: const Text('Remove',)),
          ],
        )
    );
  }

  String getTime(DateTime dateTime) {
    int hour = dateTime.hour;
    String period = 'AM';
    if (hour >= 12) {
      hour = hour - 12;
      period = 'PM';
    }
    if (hour <= 0) {
      hour = 12;
    }
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  void editSubject(List<Subject> subjects, int index) {
    // first we will calculate total

    var nameTextController = TextEditingController(text: subjects[index].name);
    var noOfMaleTextController = TextEditingController(text: subjects[index].noOfMale);
    var noOfFemaleTextController = TextEditingController(text: subjects[index].noOfFemale);
    var combinedTextController = TextEditingController(text: 'Combined');
    var fromTimeTextController = TextEditingController(text: getTime(subjects[index].fromTime));
    var toTimeTextController = TextEditingController(text: getTime(subjects[index].toTime));

    void edit() { // we will use it two times

      final updatedSubject = Subject(
        name: nameTextController.text.trim().toString(),
        noOfMale: noOfMaleTextController.text.trim().toString(),
        noOfFemale: noOfFemaleTextController.text.trim().toString(),
        fromTime: fromDate ?? subjects[index].fromTime,
        toTime: toDate ?? subjects[index].toTime,
      );

      Navigator.pop(context);

      FirestoreService().updateSubject(
        subjects[index], updatedSubject, () {
          setState(() {
            mySubjects.removeAt(index);
            mySubjects.add(updatedSubject);
          });
        }
      );
    }

    void addToCombined() {
      if (noOfMaleTextController.text.trim().toString().isEmpty && noOfFemaleTextController.text.trim().toString().isEmpty) {
        combinedTextController.text = 'Combined: 0';
      } else if (noOfMaleTextController.text.trim().toString().isEmpty) {
        combinedTextController.text = 'Combined: ${noOfFemaleTextController.text.trim()}';
      } else if (noOfFemaleTextController.text.trim().toString().isEmpty) {
        combinedTextController.text = 'Combined: ${noOfMaleTextController.text.trim()}';
      } else {
        combinedTextController.text = 'Combined: ${int.parse(noOfMaleTextController.text.trim()) + int.parse(noOfFemaleTextController.text.trim())}';
      }
    }

    showDialog(context: context, builder: (context) => SimpleDialog(
        contentPadding: EdgeInsets.zero,
        children : [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Subject', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                  const SizedBox(height: 15.0,),
                  Row(
                    children: [
                      timeContainer(fromTimeTextController, 'From Time', true),
                      const SizedBox(width: 5.0,),
                      timeContainer(toTimeTextController, 'To Time', false),
                    ],
                  ),
                  TextField(
                    controller: nameTextController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Subject name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: noOfMaleTextController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      addToCombined();
                    },
                    decoration: const InputDecoration(
                      hintText: 'No. of Male',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: noOfFemaleTextController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      addToCombined();
                    },
                    decoration: const InputDecoration(
                      hintText: 'No. of Female',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextField(
                    controller: combinedTextController,
                    readOnly: true,
                    enabled: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 5.0,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // we will disable buttons to avoid repress button, recalling function
                      TextButton(
                          onPressed: ()=> Navigator.pop(context),
                          child: const Text('Cancel')
                      ),
                      TextButton(
                          onPressed: edit,
                          child: const Text('Edit',)
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ]
    ));

  }

  @override
  void initState() {
    mySubjects = widget.user.subjects;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subjects'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('My Subjects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                GestureDetector(
                  onTap: ()=> addSubject(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.0),
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5.0,),
          Expanded(
            child: (mySubjects.isEmpty)? const Padding(
              padding: EdgeInsets.only(top: 25.0),
              child: Text('No subject'),
            ) : ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: mySubjects.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.book, color: Colors.grey[600],),
                            const SizedBox(width: 15.0,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.5,
                                  child: Text(mySubjects[index].name,
                                    style: const TextStyle(fontSize: 16.0,),
                                  ),
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('From ${getTime(mySubjects[index].fromTime)} to ${getTime(mySubjects[index].toTime)}',
                                        style: const TextStyle(fontSize: 11.0,),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text('Males: ${mySubjects[index].noOfMale} - Females: ${mySubjects[index].noOfFemale}',
                                        style: const TextStyle(fontSize: 11.0,),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            GestureDetector(
                                onTap: ()=> editSubject(widget.user.subjects, index),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0,),
                                  child: Text('Edit', style: TextStyle(color: myColor, fontWeight: FontWeight.bold),),
                                )
                            ),
                            GestureDetector(
                                onTap: ()=> removeSubject(widget.user.subjects, index),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0,),
                                  child: Text('Remove', style: TextStyle(color: myColor, fontWeight: FontWeight.bold),),
                                )
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void pickTime(TextEditingController textController, bool isFromDate) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      // Combine the selected time with today's date to create a DateTime object
      final now = DateTime.now();
      final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      textController.text = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      if (isFromDate) {
        fromDate = dateTime;
      } else {
        toDate = dateTime;
      }
    }
  }

  Widget timeContainer(TextEditingController textController, String label, bool isFromDate) {
    return Expanded(
      child: GestureDetector(
        onTap: ()=> pickTime(textController, isFromDate),
        child: TextField(
          readOnly: true,
          enabled: false,
          controller: textController,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: myColor),
            disabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: myColor)
            ),
          ),
        ),
      ),
    );
  }

}
