import 'dart:io';
import 'package:tracked/screens/profile_screens/school_info.dart';
import 'package:tracked/utils/consts.dart';
import 'package:tracked/widgets/my_outlined_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:tracked/models/user.dart' as model;
import 'package:path_provider/path_provider.dart';
import 'about_app.dart';
import 'manage_groups.dart';
import 'my_grades.dart';
import 'my_subjects.dart';

class ProfilePage extends StatefulWidget {
  final model.User user;
  File? image;
  final Function onPhotoUpdated;
  ProfilePage({Key? key, required this.user, required this.image, required this.onPhotoUpdated}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  void saveProfilePhoto() {

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Upload Profile Photo'),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              return;
            },
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                var image = await ImagePicker().pickImage(source: ImageSource.gallery);

                if (image == null) {
                  Fluttertoast.showToast(msg: 'Not able to upload photo');
                  return;
                }

                final appDirectory = await getApplicationDocumentsDirectory();
                final imagePath = '${appDirectory.path}/profile_photo.png';

                final File imageFile = File(imagePath);

                if (await imageFile.exists()) {
                  await imageFile.delete();
                }

                await imageFile.writeAsBytes(await image.readAsBytes()).then((value) {
                  setState(() {
                    widget.image = File(image.path);
                    widget.onPhotoUpdated();
                  });
                });

              } on PlatformException catch(e) {
              Fluttertoast.showToast(msg: e.toString());
              }
            },
            child: const Text('Open Gallery')
        ),
        Visibility(
          visible: widget.image != null,
          child: TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  final appDirectory = await getApplicationDocumentsDirectory();
                  final imagePath = '${appDirectory.path}/profile_photo.png';
                  final imageFile = File(imagePath);

                  if (await imageFile.exists()) {
                    await imageFile.delete();
                    Fluttertoast.showToast(msg: 'Photo removed successfully');
                  }

                  setState(() {
                    widget.onPhotoUpdated();
                  });

                } catch (e) {
                  Fluttertoast.showToast(msg: 'Error removing photo: $e');
                }
              },
              child: const Text('Remove Photo')
          ),
        ),
      ],
    ),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              (widget.user.role == 'Guard')? guardProfile() : teacherProfile(),
              const SizedBox(height: 50.0,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    Visibility(
                      visible: widget.user.role == 'Guard',
                      child: Column(
                        children: [
                          MyOutlinedButton(
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(builder: (context) => SchoolInfoScreen(user: widget.user),),
                              );
                            },
                            text: 'School Info',
                          ),
                          const SizedBox(height: 10.0,),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: widget.user.role != 'Guard',
                      child: Column(
                        children: [
                          MyOutlinedButton(
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(builder: (context) => MySubjectScreen(user: widget.user),),
                              );
                            },
                            text: 'My Subject',
                          ),
                          const SizedBox(height: 10.0,),
                        ],
                      ),
                    ),
                    MyOutlinedButton(
                      onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => ManageGroups(groups: widget.user.groups,),),
                        );
                      },
                      text: 'Emergency Text',
                    ),
                    Visibility(
                        visible: (widget.user.role == 'Admin' && widget.user.schoolID != 'superAdmin') || widget.user.role == 'Guard',
                        child: Column(
                          children: [
                            const SizedBox(height: 10.0,),
                            MyOutlinedButton(
                              onTap: () {
                                Navigator.push(context,
                                  MaterialPageRoute(builder: (context) => const MyGrades(),),
                                );
                              },
                              text: 'Grades and Sections',
                            ),
                          ],
                        ),
                    ),
                    const SizedBox(height: 10.0,),
                    MyOutlinedButton(
                      onTap: () {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (context) => AboutAppScreen(user: widget.user,),),
                        );
                      },
                      text: 'About TrackED',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25.0,),
            ],
          ),
        )
      )
    );
  }

  Widget teacherProfile() {
    return  Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SingleChildScrollView(
        child:
          profileInfo(),
      ),
    );
  }

  Widget guardProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: profileInfo(),
    );
  }

  void editProfile() {
    var nameEditingController = TextEditingController(text: widget.user.name);
    var genderEditingController = TextEditingController(text: widget.user.gender);
    var majorEditingController = TextEditingController(text: widget.user.major);

    if (widget.user.role != 'Guard') { // for Admin and Teacher

      showDialog(context: context, builder: (context) => SimpleDialog(
        title: const Text('Edit Profile', style: TextStyle(fontSize: 16.0),),
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.35,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10.0,),
                    TextField(
                      controller: nameEditingController,
                      decoration: const InputDecoration(
                        label: Text('New name'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 7.5,),
                    TextField(
                      controller: genderEditingController,
                      decoration: const InputDecoration(
                        label: Text('Gender'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 7.5,),
                    TextField(
                      controller: majorEditingController,
                      decoration: const InputDecoration(
                        label: Text('Major'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 7.5,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel')
                        ),
                        TextButton(
                            onPressed: () async {
                              if (widget.user.name != nameEditingController.text.trim()
                                  || widget.user.gender != genderEditingController.text.trim()
                                  || widget.user.major != majorEditingController.text.trim()) {

                                if (nameEditingController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name can\'t be empty')));
                                  return;
                                }

                                widget.user.name = nameEditingController.text.trim();
                                widget.user.gender = genderEditingController.text.trim();
                                widget.user.major = majorEditingController.text.trim();

                                Navigator.pop(context);

                                try {
                                  await FirebaseFirestore.instance.collection('users')
                                      .doc(widget.user.pin)
                                      .update({'name': widget.user.name, 'gender': widget.user.gender, 'major': widget.user.major});

                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              }
                            },
                            child: const Text('Update')
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),);

    } else { // for Guard

      showDialog(context: context, builder: (context) => SimpleDialog(
        title: const Text('Edit Profile', style: TextStyle(fontSize: 16.0),),
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10.0,),
                    TextField(
                      controller: nameEditingController,
                      decoration: const InputDecoration(
                        label: Text('New name'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 7.5,),
                    TextField(
                      controller: genderEditingController,
                      decoration: const InputDecoration(
                        label: Text('Gender'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 7.5,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel')
                        ),
                        TextButton(
                            onPressed: () async {
                              if (widget.user.name != nameEditingController.text.trim()
                                  || widget.user.gender != genderEditingController.text.trim()) {

                                if (nameEditingController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name can\'t be empty')));
                                  return;
                                }

                                widget.user.name = nameEditingController.text.trim();
                                widget.user.gender = genderEditingController.text.trim();

                                Navigator.pop(context);

                                try {
                                  await FirebaseFirestore.instance.collection('users')
                                      .doc(widget.user.pin)
                                      .update({'name': widget.user.name, 'gender': widget.user.gender});

                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                                }
                              }
                            },
                            child: const Text('Update')
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),);

    }
  }

  Widget profileInfo() {
    var size = MediaQuery.of(context).size;
    var color = (MediaQuery.of(context).platformBrightness == Brightness.light) ? Colors.black : Colors.white.withOpacity(0.6);
    var portrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: size.width * 0.55,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15.0,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('MY PROFILE', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                  const SizedBox(width: 7.5,),
                  GestureDetector(
                      onTap: editProfile,
                      child: const Text('Edit',
                        style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: myColor, decoration: TextDecoration.underline),
                      ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0,),
              RichText(text: TextSpan(
                text: 'Full Name: ',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
                children: [
                  TextSpan(
                    text: widget.user.name,
                    style: const TextStyle(fontWeight: FontWeight.normal,),
                  )
                ]
              )),
              // const SizedBox(height: 10.0,),
              // RichText(text: TextSpan(
              //     text: 'Gender: ',
              //     style: TextStyle(fontWeight: FontWeight.bold, color: color),
              //     children: [
              //       TextSpan(
              //         text: widget.user.gender.isEmpty ? 'Not mentioned' : widget.user.gender,
              //         style: const TextStyle(fontWeight: FontWeight.normal,),
              //       )
              //     ]
              // )),
              const SizedBox(height: 10.0,),
              Visibility(
                visible: widget.user.schoolID != 'superAdmin',
                child: Column(
                  children: [
                    RichText(text: TextSpan(
                        text: 'School Assigned: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                        children: [
                          TextSpan(
                            text: widget.user.schoolName,
                            style: const TextStyle(fontWeight: FontWeight.normal,),
                          )
                        ]
                    )),
                    const SizedBox(height: 10.0,),
                  ],
                ),
              ),
              RichText(text: TextSpan(
                  text: 'Role: ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  children: [
                    TextSpan(
                      text: widget.user.role,
                      style: const TextStyle(fontWeight: FontWeight.normal,),
                    )
                  ]
              )),
              const SizedBox(height: 10.0,),
              Visibility(
                visible: widget.user.role != 'Guard',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // RichText(text: TextSpan(
                    //     text: 'Major: ',
                    //     style: TextStyle(fontWeight: FontWeight.bold, color: color),
                    //     children: [
                    //       TextSpan(
                    //         text: widget.user.major.isEmpty ? 'Not mentioned' : widget.user.major,
                    //         style: const TextStyle(fontWeight: FontWeight.normal,),
                    //       )
                    //     ]
                    // )),
                    // const SizedBox(height: 10.0,),
                    RichText(text: TextSpan(
                        text: 'Subjects: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color),
                        children: [
                          TextSpan(
                            text: widget.user.subjects.isEmpty? 'No subject' : widget.user.subjects.map((e) => e.name).toList().join(', '),
                            style: const TextStyle(fontWeight: FontWeight.normal,),
                          )
                        ]
                    ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 25.0,),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10.0,),
        GestureDetector(
          onTap: saveProfilePhoto,
          child: Container(
            width: portrait? size.width * 0.30 : size.width * 0.20,
            height: portrait? size.width * 0.30 : size.width * 0.20,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: (widget.image != null)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(5.0),
                child: Image.file(widget.image!, fit: BoxFit.cover,)
            )
            : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add_alt_1, color: Colors.grey, size: portrait? size.width * 0.25 : size.width * 0.15,),
                const Text('Upload Photo', style: TextStyle(fontSize: 10.0, color: Colors.grey,),),
              ],
            ),
          ),
        )
      ],
    );
  }
}
