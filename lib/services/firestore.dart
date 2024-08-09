import 'package:tracked/models/Student.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tracked/models/user.dart' as model;

import '../models/group.dart';
import '../models/subject.dart';

class FirestoreService {
  final user = FirebaseAuth.instance.currentUser;

  String? getPin() {
    String? email = user?.email;
    // user_123456@school.com // get 123456 as pin
    String? pin = email?.substring(email.indexOf('_') + 1, email.indexOf('@'));
    return pin;
  }

  DocumentReference<Map<String, dynamic>> getDocInstance() =>
     FirebaseFirestore.instance.collection('users').doc(getPin());

  Stream<model.User?> getUserStream(BuildContext context) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(getPin())
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return model.User.fromJson(snapshot.data());
      }

      if (!snapshot.exists) {
        showDialog(context: context, builder: (context) => const AlertDialog(
          title: Text('The user may be deleted!'),
        ),).then((value) {
          FirebaseAuth.instance.signOut();
        });
      }

      return null;
    });
  }

  Future<void> addSubject(Subject subject, Function then) async {

    await getDocInstance().update({
      'subjects': FieldValue.arrayUnion([subject.toJson()])
    }).then((value) => then())
      .catchError((error) {
        Fluttertoast.showToast(msg: 'Subject may not added');
      }
    );
  }

  Future<void> removeSubject(Subject subject, Function then) async {
    await getDocInstance().update({
      'subjects': FieldValue.arrayRemove([subject.toJson()])
    }).then((value) => then())
      .catchError((error) {
        Fluttertoast.showToast(msg: 'Subject may not removed');
      }
    );
  }

  Future<void> updateSubject(Subject oldSubject, Subject updatedSubject, Function then) async {
    await getDocInstance().update({
      'subjects': FieldValue.arrayRemove([oldSubject.toJson()]),
    }).then((value) {
      getDocInstance().update({
        'subjects': FieldValue.arrayUnion([updatedSubject.toJson()])
      }).then((value) => then())
      .catchError((error) {
        Fluttertoast.showToast(msg: 'Subject may not be edited');
      });
    })
      .catchError((error) {
      Fluttertoast.showToast(msg: 'Subject may not be edited');
    }
    );
  }

  Future<void> saveReport(Student student, Function then) async {
    await getDocInstance().update({
      'studentsReport': FieldValue.arrayUnion([student.toJson()])
    }).then((value) => then())
      .catchError((error) {
        Fluttertoast.showToast(msg: 'Report may not added!');
    });
  }

  Future<void> deleteAllReports() async {
    final docRef = getDocInstance();
    final userDoc = await docRef.get();

    await docRef.update({
      ...?userDoc.data(), // preserve existing fields
      'studentsReport': FieldValue.delete(),
    });
  }

  Future<void> addGroup(Group group, Function then) async {
    await getDocInstance().update({
      'groups': FieldValue.arrayUnion([group.toJson()])
    }).then((value) => then())
        .catchError((error) {
      Fluttertoast.showToast(msg: 'Something went wrong');
    });
  }

  Future<void> removeGroup(Group group, Function then) async {
    await getDocInstance().update({
      'groups': FieldValue.arrayRemove([group.toJson()])
    }).then((value) => then())
        .catchError((error) {
      Fluttertoast.showToast(msg: 'Something went wrong');
    });
  }

  Future<void> addPhoneNumber(int indexOfGroup, String name, String number) async {
    final docRef = getDocInstance();

    final docSnapshot = await docRef.get();
    final groupList = docSnapshot.data()?['groups'] as List<dynamic>;

    final group = groupList[indexOfGroup];
    final phoneNumbers = Map<String, dynamic>.from(group['phoneNumbers']);
    phoneNumbers[name] = number; // or any value

    final updatedGroup = Map<String, dynamic>.from(group);
    updatedGroup['phoneNumbers'] = phoneNumbers;

    final updatedGroupList = List<dynamic>.from(groupList);
    updatedGroupList[indexOfGroup] = updatedGroup;

    await docRef.update({'groups': updatedGroupList});
  }

  Future<void> removePhoneNumber(int groupIndex, String name) async {
    final docRef = getDocInstance();

    final docSnapshot = await docRef.get();
    final groupList = docSnapshot.data()?['groups'] as List<dynamic>;

    final group = groupList[groupIndex];
    final phoneNumbers = Map<String, dynamic>.from(group['phoneNumbers']);
    phoneNumbers.remove(name);

    final updatedGroup = Map<String, dynamic>.from(group);
    updatedGroup['phoneNumbers'] = phoneNumbers;

    final updatedGroupList = List<dynamic>.from(groupList);
    updatedGroupList[groupIndex] = updatedGroup;

    await docRef.update({'groups': updatedGroupList});
  }

  Future<void> editPhoneNumber(int groupIndex, String oldName, String newName, String newNumber) async {
    final docRef = getDocInstance();

    final docSnapshot = await docRef.get();
    final groupList = docSnapshot.data()?['groups'] as List<dynamic>;

    final group = groupList[groupIndex];
    final phoneNumbers = Map<String, dynamic>.from(group['phoneNumbers']);

    if (!phoneNumbers.containsKey(oldName)) {
      throw Exception('Phone number with name $oldName does not exist');
    }

    // Update the phone number
    phoneNumbers[newName] = phoneNumbers[oldName];
    phoneNumbers.remove(oldName);
    phoneNumbers[newName] = newNumber;

    final updatedGroup = Map<String, dynamic>.from(group);
    updatedGroup['phoneNumbers'] = phoneNumbers;

    final updatedGroupList = List<dynamic>.from(groupList);
    updatedGroupList[groupIndex] = updatedGroup;

    await docRef.update({'groups': updatedGroupList});
  }

}
