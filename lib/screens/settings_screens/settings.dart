import 'package:tracked/screens/settings_screens/add_school.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/consts.dart';
import '../../models/school.dart';
import 'add_user_super_admin.dart';
import 'manage_user.dart';

class SettingsPage extends StatefulWidget {
  final String role;
  final bool isSuperAdmin;
  const SettingsPage({Key? key, required this.role, required this.isSuperAdmin,}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<School> schools = [];
  bool connection = false;

  void fetchSchools() async {

    schools.clear();

    try {
      await FirebaseFirestore.instance
          .collection('schools')
          .get()
          .then((QuerySnapshot querySnapshot) {
            connection = true;
            schools.clear();

        for (var doc in querySnapshot.docs) {
          schools.add(School.fromJson(doc.data() as Map<String, dynamic>));
        }

        if (mounted) {
          setState(() {
            // Your state change code goes here
          });
        }
      });
    } on FirebaseException {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              content: Text('Not able to get schools name'),
            );
          }
      );
    }
  }

  void editSchool(String id, String name, String address) async {

    var nameController = TextEditingController(text: name);
    var addressController = TextEditingController(text: address);

    void update() async {
      try {
        Navigator.pop(context);

        await FirebaseFirestore.instance.collection('schools')
            .doc(id)
            .update({'name': nameController.text.trim().isEmpty ? name : nameController.text.trim(),
              'address': addressController.text.trim().toString()}).then((value) {
                setState(() {
                  fetchSchools();
                });
        });
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Edit School', style: TextStyle(fontSize: 16.0,),),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'New name',
            ),
          ),
          const SizedBox(height: 5.0,),
          TextField(
            controller: addressController,
            decoration: const InputDecoration(
              hintText: 'New Address',
            ),
          ),
          const SizedBox(height: 5.0,),
          TextButton(onPressed: update , child: const Text('Update')),
        ],
      ),
    ),);
  }

  @override
  void initState() {
    fetchSchools();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('List of Schools', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                  IconButton(
                      onPressed: (){
                        showDialog(context: context, builder: (context) => SimpleDialog(
                          children: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddSchool(),),)
                                      .then((value) { if (mounted) {
                                    fetchSchools();
                                  }}
                                  );
                                },
                                child: const Text('Add school')
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AddUserSuperAdmin(),),)
                                      .then((value) { if (mounted) {
                                    schools.clear();
                                    fetchSchools();
                                  }}
                                  );
                                },
                                child: const Text('Add User')
                            ),
                          ],
                        ),);
                      },
                      icon: const Icon(Icons.add,)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5.0,),
            (schools.isEmpty)? (connection)? const Padding(
              padding: EdgeInsets.only(top: 30.0),
              child: Center(child: Text('There is no school present!')),
            ) : const Padding(
              padding: EdgeInsets.only(top: 30.0),
              child: Center(child: Text('Loading schools')),
            )
            : Expanded(
              child: ListView.builder(
                itemCount: schools.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: ()=> (schools.isEmpty) ? null : Navigator.push(
                    context, MaterialPageRoute(builder: (context) => ManageUserScreen(
                      isSuperAdmin: widget.isSuperAdmin,
                      schoolName: schools[index].name,
                      schoolID: schools[index].id,
                  ),)
                  ).then((value) {
                    fetchSchools();
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(schools[index].name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(schools[index].id),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10.0,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                GestureDetector(onTap: ()=> editSchool(schools[index].id, schools[index].name, schools[index].address),
                                  child: const Padding(
                                    padding: EdgeInsets.only(bottom: 3.0),
                                    child: Text('Edit', style: TextStyle(color: myColor, fontWeight: FontWeight.bold),),
                                  ),
                                ),
                                Text('Users: ${schools[index].schoolUsersRef.length}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      )
    );
  }
}
