import 'package:tracked/utils/consts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tracked/models/user.dart' as model;

class AboutAppScreen extends StatefulWidget {
  final model.User user;
  const AboutAppScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String appDescription = '';
  String email = '';
  String contactNumber = '';
  String customField = '';

  Stream<Map<String, dynamic>?> getAppInfo() {
    return FirebaseFirestore.instance
        .collection('app_info')
        .doc('information')
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }


  Future<void> editAppInfo(String appDescription, String email, String contactNumber, String customField) async {
    await FirebaseFirestore.instance
        .collection('app_info')
        .doc('information')
        .update({'appDescription': appDescription, 'email': email, 'contactNumber': contactNumber, 'customField': customField});
  }

  void editInfo() {
    var descriptionController = TextEditingController(text: appDescription);
    var emailController = TextEditingController(text: email);
    var contactNumberController = TextEditingController(text: contactNumber);
    var customFieldController = TextEditingController(text: customField);

    void edit() async {
      Navigator.pop(context);

      if (descriptionController.text == appDescription && emailController.text == email && contactNumberController.text == contactNumber && customFieldController.text == customField) {
        return;
      }

      if (widget.user.schoolID != 'superAdmin') {
        return;
      }

      await FirebaseFirestore.instance
        .collection('app_info')
        .doc('information')
        .update({
          'appDescription': descriptionController.text,
          'email': emailController.text,
          'contactNumber': contactNumberController.text,
          'customField': customFieldController.text,
        });
    }

    showDialog(context: context, builder: (context) => SimpleDialog(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0,),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Info'),
              const SizedBox(height: 5.0,),
              TextField(
                controller: descriptionController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Enter Description',
                ),
              ),
              const SizedBox(height: 5.0,),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: 'Enter Email Address',
                ),
              ),
              const SizedBox(height: 5.0,),
              TextField(
                controller: contactNumberController,
                decoration: const InputDecoration(
                  hintText: 'Enter Contact Number',
                ),
              ),
              const SizedBox(height: 5.0,),
              TextField(
                keyboardType: TextInputType.multiline,
                maxLines: null,
                controller: customFieldController,
                decoration: const InputDecoration(
                  hintText: 'Enter Custom Field',
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
                  const SizedBox(width: 10.0),
                  TextButton(
                      onPressed: edit,
                      child: const Text('Add',)
                  ),
                ],
              )
            ],
          ),
        )
      ],
    ),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About TrackED'),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: getAppInfo(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Cannot fetch info right now...', textAlign: TextAlign.center,),);
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // if has data
          if (snapshot.data != null) {
            appDescription = snapshot.data!['appDescription'];
            email = snapshot.data!['email'];
            contactNumber = snapshot.data!['contactNumber'];
            customField = snapshot.data!['customField'];
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TrackED', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
                      Visibility(
                        visible: widget.user.schoolID == 'superAdmin',
                        child: GestureDetector(
                          onTap: editInfo,
                          child: const Text('Edit', style: TextStyle(color: myColor),),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20.0,),
                  Text(appDescription,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 35.0,),
                  const Text('Need Help? Please don\'t hesitate to contact us, we\'re here to help!',
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15.0,),
                  Row(
                    children: [
                      const Text('Email Address: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      (email.isNotEmpty)? SelectableText(email,
                        style: const TextStyle(fontSize: 16.0,),
                      ) : const Text('Not Mentioned', style: TextStyle(fontSize: 16.0,))
                    ],
                  ),
                  const SizedBox(height: 2.5),
                  Row(
                    children: [
                      const Text('Contact Number: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      (contactNumber.isNotEmpty)? SelectableText(contactNumber,
                        style: const TextStyle(fontSize: 16.0,),
                      ) : const Text('Not Mentioned', style: TextStyle(fontSize: 16.0,))
                    ],
                  ),
                  const SizedBox(height: 15.0,),
                  Text(customField,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 20.0,),
                  const Text('Thank you!',
                    style: TextStyle(fontSize: 16.0),
                  )
                ],
              ),
            ),
          );
        },
      )
    );
  }
}
