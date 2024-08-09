import 'package:tracked/utils/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tracked/models/user.dart' as model;

import '../../models/school.dart';
import '../../models/subject.dart';
import '../../services/firestore.dart';

class SchoolInfoScreen extends StatefulWidget {
  final model.User user;
  const SchoolInfoScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<SchoolInfoScreen> createState() => _SchoolInfoScreenState();
}

class _SchoolInfoScreenState extends State<SchoolInfoScreen> {
  School school = School(name: '', abbreviation: '', id: '', address: '- - -', schoolUsersRef: []);
  var totalEnrollees = '';

  void fetchSchool() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('schools')
        .doc(widget.user.schoolID).get();

    school = School.fromJson(snapshot.data());

    setState(() {

    });
  }

  void editEnrollees() {
    final enrolleesController = TextEditingController();
    final noOfMalesController = TextEditingController();
    final noOfFemalesController = TextEditingController();

    void edit() {
      if (noOfMalesController.text.isEmpty || noOfFemalesController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fields cannot be empty!')));
        return;
      }

      final updatedSubject = Subject(
        name: widget.user.subjects[0].name,
        noOfMale: noOfMalesController.text.trim().toString(),
        noOfFemale: noOfFemalesController.text.trim().toString(),
        fromTime: widget.user.subjects[0].fromTime,
        toTime: widget.user.subjects[0].toTime,
      );

      Navigator.pop(context);

      FirestoreService().updateSubject(
          widget.user.subjects[0], updatedSubject, () {}
      );

      setState(() {
        totalEnrollees = enrolleesController.text.trim().toString();
        widget.user.subjects[0].noOfMale = noOfMalesController.text.trim().toString();
        widget.user.subjects[0].noOfFemale = noOfFemalesController.text.trim().toString();
      });
    }

    showDialog(context: context, builder: (context) => SimpleDialog(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: enrolleesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Total Enrollees'
                ),
              ),
              TextField(
                controller: noOfMalesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'Total Males'
                ),
              ),
              TextField(
                controller: noOfFemalesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    hintText: 'Total Females'
                ),
              ),
              const SizedBox(height: 5.0,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(onPressed: edit, child: const Text('Edit')),
                ],
              ),
            ],
          ),
        ),
      ],
    ),);
  }

  @override
  void initState() {
    fetchSchool();
    totalEnrollees = '${int.parse(widget.user.subjects[0].noOfMale) + int.parse(widget.user.subjects[0].noOfFemale)}';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var color = (MediaQuery.of(context).platformBrightness == Brightness.light) ? Colors.black : Colors.white.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        title: const Text('School Information'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10.0,),
              Center(
                child: Text(widget.user.schoolName,
                  style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 5.0,),
              Center(
                child: Text((school.address.trim().isEmpty)? 'Not mentioned' : school.address,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16.0,),
                ),
              ),
              const SizedBox(height: 5.0,),
              Center(
                  child: RichText(
                    text: TextSpan(
                        text: 'SCHOOL ID: ',
                        style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: color),
                        children: [
                          TextSpan(text: widget.user.schoolID, style: const TextStyle(fontWeight: FontWeight.normal),),
                        ]
                    ),
                  )
              ),
              const Divider(thickness: 1.0),
              const SizedBox(height: 15.0,),
              Stack(
                children: [
                  const Center(
                      child: Text('School Enrollees Status', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),)
                  ),
                  Positioned(
                    right: 5.0,
                    top: 2.0,
                    child: GestureDetector(
                      onTap: editEnrollees,
                      child: const Text('Edit', style: TextStyle(color: myColor)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0,),
              Text('Total Enrollees: $totalEnrollees'),
              const SizedBox(height: 5.0,),
              Text('Total Males: ${widget.user.subjects[0].noOfMale}'),
              const SizedBox(height: 5.0,),
              Text('Total Females: ${widget.user.subjects[0].noOfFemale}'),
              const SizedBox(height: 20.0,),
            ],
          ),
        ),
      ),
    );
  }
}
