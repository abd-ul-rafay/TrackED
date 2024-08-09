import 'package:tracked/models/school.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/my_button.dart';
import '../../widgets/my_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSchool extends StatefulWidget {
  const AddSchool({Key? key,}) : super(key: key);

  @override
  State<AddSchool> createState() => _AddSchoolState();
}

class _AddSchoolState extends State<AddSchool> {
  final _schoolNameController = TextEditingController();
  final _schoolAbbrController = TextEditingController();
  final _schoolIDController = TextEditingController();
  final _schoolPinController = TextEditingController();
  final _schoolAddressController = TextEditingController();

  Widget buttonWidget = const Text('Add School', style: TextStyle(fontSize: 16.0, color: Colors.white),);

  void addSchool() async {
    var name = _schoolNameController.text.trim().toString();
    var abbr = _schoolAbbrController.text.trim().toString();
    var id = _schoolIDController.text.trim().toString();
    var pin = _schoolPinController.text.trim().toString();
    var address = _schoolAddressController.text.trim().toString();

    if (name.isEmpty || abbr.isEmpty || id.isEmpty || pin.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields!')));
      return;
    }

    // press button, shut keyboard
    if (!FocusScope.of(context).hasPrimaryFocus) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      buttonWidget = const CircularProgressIndicator(color: Colors.white,);
    });

    final school = School(name: name, abbreviation: abbr, id: id, address: address, schoolUsersRef: []);

    try {
      await FirebaseFirestore.instance.collection('schools')
          .doc(id).set(school.toJson())
          .then((value) {
            Fluttertoast.showToast(msg: 'School added');
            Navigator.pop(context);
          });
    } on FirebaseException catch(e) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(e.message.toString()),
            );
          }
      );
    }

    setState(() {
      buttonWidget = const Text('Add School', style: TextStyle(fontSize: 16.0, color: Colors.white),);
    });

  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _schoolIDController.dispose();
    _schoolPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a School',),
        leading: IconButton(
          onPressed: ()=> Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _schoolNameController,
                  decoration: InputDecoration(
                      label: const Text('Enter School Name'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      )
                  ),
                ),
                const SizedBox(height: 17.5,),
                TextField(
                  controller: _schoolAbbrController,
                  decoration: InputDecoration(
                      label: const Text('Enter School Abbreviation'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      )
                  ),
                ),
                const SizedBox(height: 17.5,),
                MyTextField(
                  controller: _schoolIDController,
                  label: 'Enter School ID',
                  maxLength: 20,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 2.5,),
                MyTextField(
                  controller: _schoolPinController,
                  label: 'Enter School Pincode',
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 2.5,),
                TextField(
                  controller: _schoolAddressController,
                  keyboardType: TextInputType.streetAddress,
                  decoration: InputDecoration(
                      label: const Text('Enter School Address'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      )
                  ),
                ),
                const SizedBox(height: 15.0,),
                MyButton(
                  widget: buttonWidget,
                  onTap: addSchool,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
