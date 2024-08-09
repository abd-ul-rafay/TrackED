import 'package:tracked/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/consts.dart';
import '../../models/school.dart';
import 'add_user_sub_admin.dart';

class ManageUserScreen extends StatefulWidget {
  final String schoolID;
  final String schoolName;
  final bool isSuperAdmin;
  const ManageUserScreen({Key? key, required this.schoolName, required this.schoolID, required this.isSuperAdmin,}) : super(key: key);

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  School school = School(name: '', abbreviation: '', id: '', address: '', schoolUsersRef: []);
  List<User> users = [];
  Widget editIcon = const Icon(Icons.more_horiz);
  int whichIndexToShowLoad = 0;
  bool isLoaded = false;

  bool connection = false;

  void fetchSchoolAndUsers() async {

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolID).get();

      school = School.fromJson(snapshot.data());

      users.clear();

      // Now we have to fetch all users from school users ref
      for (var userRef in school.schoolUsersRef) {
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userRef).get();

        if (userDoc.exists) {
          Map<String, dynamic>? userData = userDoc.data();
          User user = User.fromJson(userData);
          setState(() {
            users.add(user);
          });
        }
      }

      if (mounted) {
        setState(() {
        isLoaded = true;
      });
      }

    } on FirebaseException {
      showDialog(
          context: context,
          builder: (context) {
            return const AlertDialog(
              content: Text('Not able to get school'),
            );
          }
      );
    }
  }

  void manageUser(String name, String pin) async {
    var nameEditingController = TextEditingController();

    setState(() {
      editIcon = const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1,));
    });

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),)),
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          deleteUser(pin, school.id);
                        },
                        child: const Icon(Icons.delete, color: myColor,)
                    )
                  ],
                ),
                const SizedBox(height: 5.0,),
                Row(
                  children: [
                    const Text('PIN: '),
                    SelectableText(pin, style: const TextStyle(decoration: TextDecoration.underline),),
                  ],
                ),
                TextField(
                  controller: nameEditingController,
                  decoration: const InputDecoration(
                    hintText: 'New name',
                  ),
                ),
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
                        onPressed: (){
                          if (name != nameEditingController.text.trim() && nameEditingController.text.trim().isNotEmpty) {
                            name = nameEditingController.text.trim();
                            
                            try {
                              FirebaseFirestore.instance.collection('users')
                                  .doc(pin)
                                  .update({'name': name}).then((value) {setState(() {fetchSchoolAndUsers();});});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                            
                          }
                          Navigator.pop(context);

                        },
                        child: const Text('Update')
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );


    setState(() {
      editIcon = const Icon(Icons.more_horiz);
    });

  }

  void deleteUser(String pin, String schoolsId) async {

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Are you sure, want to remove this user', style: TextStyle(fontSize: 14.0),),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);

                final usersCollection = FirebaseFirestore.instance.collection('users');
                final schoolsCollection = FirebaseFirestore.instance.collection('schools');

                // deleting doc of user
                await usersCollection.doc(pin).delete();

                // deleting from list of user of school
                final schoolsDoc = await schoolsCollection.doc(schoolsId).get();
                final updatedUsersList = List<String>.from(schoolsDoc['schoolUsersRef'])
                  ..remove(pin);
                await schoolsCollection.doc(schoolsId).update(
                    {'schoolUsersRef': updatedUsersList}).then((value)  {
                      fetchSchoolAndUsers();
                });

              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }

            },
            child: const Text('Remove')
        ),
      ],
    ),);

  }
  
  void addUser() {
    showDialog(context: context, builder: (context) => SimpleDialog(
      children: [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AddUserSubAdmin(school: school,),),)
                  .then((value) { if (mounted) {
                fetchSchoolAndUsers();
              }}
              );
            },
            child: const Text('Add User')
        ),
      ],
    ),);
  }

  @override
  void initState() {
    fetchSchoolAndUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int tableSrNoCount = 1;
    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;
    var color = (MediaQuery.of(context).platformBrightness == Brightness.light) ? Colors.black : Colors.white.withOpacity(0.6);

    return Scaffold(
      appBar: (widget.isSuperAdmin)? AppBar(
        title: const Text('Manage School User',),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
                onPressed: addUser,
                icon: const Icon(Icons.add,)
            ),
          ),
        ],
      )
        : null, // if it's not super admin, it's sub admin, then don't show appbar
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10.0,),
                  (!widget.isSuperAdmin)? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Manage School Users',
                        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
                      IconButton(onPressed: addUser, icon: const Icon(Icons.add))
                    ],
                  )
                    : const SizedBox(),
                  (!widget.isSuperAdmin)? const SizedBox(height: 10.0,) : const SizedBox(),
                  const SizedBox(height: 10.0,),
                  Center(
                    child: Text(widget.schoolName,
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
                          TextSpan(text: widget.schoolID, style: const TextStyle(fontWeight: FontWeight.normal),),
                        ]
                      ),
                    )
                  ),
                  const SizedBox(height: 20.0,),
                  const Text('List of Users:', style: TextStyle(fontSize: 18.0,)),
                  const SizedBox(height: 10.0,),
                ],
              ),
            ),
            (school.schoolUsersRef.isEmpty)
            ? (isLoaded)? Padding(padding: const EdgeInsets.only(top: 30), child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('No users in this school!'),
              ],
            ),) : Padding(padding: const EdgeInsets.only(top: 30), child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Loading...'),
              ],
            ),)
            : SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: TableBorder.symmetric(inside: BorderSide(width: 1, color: isDarkTheme? Colors.white12 : Colors.blue.withOpacity(0.3)),),
                        columnWidths: {
                          0: FixedColumnWidth(MediaQuery.of(context).size.width * 0.13),
                          1: FixedColumnWidth(MediaQuery.of(context).size.width * 0.20),
                          2: FixedColumnWidth(MediaQuery.of(context).size.width * 0.37),
                          3: FixedColumnWidth(MediaQuery.of(context).size.width * 0.26),
                        },
                        children: [
                          TableRow(
                              children: [
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: const Center(
                                      child: Text('NO.',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0,),
                                    child: const Text('PINCODE',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),
                                      overflow: TextOverflow.fade,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    )
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: const Text('FULLNAME',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    )
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: const Text('ROLE',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    )
                                ),
                              ]
                          ),

                          for (var user in users)
                            TableRow(
                              children: [
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text('${tableSrNoCount++}.', style: const TextStyle(fontSize: 12.0), textAlign: TextAlign.center,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: GestureDetector(onTap: ()=> manageUser(user.name, user.pin),
                                        child: Text(user.pin, overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 12.0, decoration: TextDecoration.underline,),))
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(user.name, style: const TextStyle(fontSize: 12.0), overflow: TextOverflow.ellipsis, maxLines: 1,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      children: [
                                        if (user.role == 'Admin')
                                          Image.asset('assets/images/admin_logo.png', color: isDarkTheme? Colors.grey : Colors.black,  width: 16.0, height: 16.0,),
                                        if (user.role == 'Teacher')
                                          Image.asset('assets/images/teacher_logo.png', color: isDarkTheme? Colors.grey : Colors.black,  width: 16.0, height: 16.0,),
                                        if (user.role == 'Guard')
                                          Image.asset('assets/images/guard_logo.png', color: isDarkTheme? Colors.grey : Colors.black, width: 16.0, height: 16.0,),

                                        const SizedBox(width: 5.0,),
                                        Text(user.role, style: const TextStyle(fontSize: 12.0,), overflow: TextOverflow.ellipsis, maxLines: 1,),
                                      ],
                                    )
                                ),
                              ]
                            )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0,)
                ],
              ),
            )
          ],
        ),
      )
    );
  }
}
