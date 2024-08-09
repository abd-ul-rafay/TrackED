import 'dart:math';
import 'package:tracked/models/school.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../models/subject.dart';
import '../../utils/consts.dart';
import '../../models/group.dart';
import '../../widgets/my_button.dart';
import '../../widgets/my_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tracked/models/user.dart' as model;

class AddUserSubAdmin extends StatefulWidget {
  final School school;
  const AddUserSubAdmin({Key? key, required this.school,}) : super(key: key);

  @override
  State<AddUserSubAdmin> createState() => _AddUserSubAdminState();
}

class _AddUserSubAdminState extends State<AddUserSubAdmin> {
  final _userNameController = TextEditingController();
  final _userPinController = TextEditingController();
  final _userGenderController = TextEditingController();
  final _userMajorController = TextEditingController();

  List<String> roleUser = ['Teacher', 'Guard', 'Admin'];
  String roleDropDownValue = ''; // changed in init-state

  Widget buttonWidget = const Text('Add User', style: TextStyle(fontSize: 16.0, color: Colors.white),);

  Future<UserCredential?> addUser() async {

    var name = _userNameController.text.trim().toString();
    var pin = _userPinController.text.trim().toString();
    var gender = _userGenderController.text.trim().toString();
    var major = _userMajorController.text.trim().toString();

    if (name.isEmpty || pin.isEmpty || gender.isEmpty || major.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields!')));
      return null;
    }

    // press button, shut keyboard
    if (!FocusScope.of(context).hasPrimaryFocus) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      buttonWidget = const CircularProgressIndicator(color: Colors.white,);
    });

    FirebaseApp app = await Firebase.initializeApp(
        name: 'Secondary', options: Firebase.app().options);

    UserCredential? userCredential;

    try {
      userCredential = await FirebaseAuth.instanceFor(app: app).createUserWithEmailAndPassword(
        email: 'user_$pin@school.com',
        password: pin,
      ).then((value) async {

        final user = model.User(
          name: name,
          pin: pin,
          role: roleDropDownValue,
          gender: gender,
          major: major,
          schoolName: widget.school.name,
          schoolAbbr: widget.school.abbreviation,
          schoolID: widget.school.id,
          schoolAddress: widget.school.address,
          subjects: roleDropDownValue == 'Guard'? // then create single subject for saving total no. of males and females
            [Subject(name: '', noOfMale: '0', noOfFemale: '0', fromTime: DateTime.now(), toTime: DateTime.now(),)] : [],
          studentsReport: [],
          groups: [Group(name: 'Demo Group', phoneNumbers: {})],
        );

        await FirebaseFirestore.instance.collection('users')
            .doc(pin).set(user.toJson());

        // now after adding user we have to add user in schools list
        await FirebaseFirestore.instance.collection('schools')
            .doc(widget.school.id).update({
          'schoolUsersRef': FieldValue.arrayUnion([user.pin])
        }).then((value) {
          Fluttertoast.showToast(msg: 'User added');
          Navigator.pop(context);
        });

        return value;
      });

    } on FirebaseException catch(e) {
      setState(() {
        buttonWidget = const Text('Add User', style: TextStyle(fontSize: 16.0, color: Colors.white),);
      });

      if(e.code == 'email-already-in-use') {
        showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: Text('Pin already used!'),
              );
            }
        );
        return null;
      }

      if(e.code == 'invalid-email') {
        showDialog(
            context: context,
            builder: (context) {
              return const AlertDialog(
                content: Text('Pin format not correct!'),
              );
            }
        );
        return null;
      }

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
      buttonWidget = const Text('Add User', style: TextStyle(fontSize: 16.0, color: Colors.white),);
    });

    await app.delete();
    return Future.sync(() => userCredential);

  }

  int generateRandomNumber() {
    Random random = Random();
    return random.nextInt(900000) + 100000;
  }

  @override
  void initState()  {

    // first we will auto(random) generate user's pin
    _userPinController.text = generateRandomNumber().toString();

    roleDropDownValue = roleUser[0];
    super.initState();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User',),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10.0,),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.5, vertical: 5.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(color: Colors.grey)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          DropdownButton(
                            value: roleDropDownValue,
                            icon: const Icon(Icons.arrow_downward_rounded, color: myColor,),
                            items: roleUser.map((String items) {
                              return DropdownMenuItem(
                                value: items,
                                child: Text(items, style: const TextStyle(color: myColor),),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                roleDropDownValue = newValue!;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                        top: 3.5,
                        left: 12,
                        child: Text('Role', style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),)
                    ),
                  ],
                ),
                const SizedBox(height: 10.0,),
                Stack(
                  children: [
                    TextField(
                      controller: _userNameController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          )
                      ),
                    ),
                    Positioned(
                        top: 3.5,
                        left: 12,
                        child: Text('Username', style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),)
                    ),
                  ],
                ),
                const SizedBox(height: 10.0,),
                Stack(
                  children: [
                    TextField(
                      controller: _userGenderController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          )
                      ),
                    ),
                    Positioned(
                        top: 3.5,
                        left: 12,
                        child: Text('Gender', style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),)
                    ),
                  ],
                ),
                const SizedBox(height: 10.0,),
                Stack(
                  children: [
                    TextField(
                      controller: _userMajorController,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          )
                      ),
                    ),
                    Positioned(
                        top: 3.5,
                        left: 12,
                        child: Text('Major', style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),)
                    ),
                  ],
                ),
                const SizedBox(height: 10.0,),
                Stack(
                  children: [
                    MyTextField(
                      controller: _userPinController,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      label: '',
                    ),
                    Positioned(
                        top: 3.5,
                        left: 12,
                        child: Text('Pincode', style: TextStyle(fontSize: 10.0, color: Colors.grey[600]),)
                    ),
                  ],
                ),
                const SizedBox(height: 10.0,),
                MyButton(
                  widget: buttonWidget,
                  onTap: addUser,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
