import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import 'package:tracked/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/grade.dart';
import '../../models/grade_student.dart';
import '../../models/section.dart';
import '../../services/grade_manager.dart';

class SaveStudentAndQrCode extends StatefulWidget {
  final Grade grade;
  final Section section;
  final GradeStudent student;
  final File? image;
  final String codeData;
  final bool edit;
  const SaveStudentAndQrCode({Key? key, required this.codeData, required this.grade, required this.section, required this.student, required this.image, this.edit = false,}) : super(key: key);

  @override
  State<SaveStudentAndQrCode> createState() => _SaveStudentAndQrCodeState();
}

class _SaveStudentAndQrCodeState extends State<SaveStudentAndQrCode> {
  GradeStorage gradeStorage = GradeStorage();
  final GlobalKey _globalKey = GlobalKey();

  Future<void> saveImage(File image, String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/$name.jpg';

    // Check if the file already exists
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    try {
      await file.writeAsBytes(await image.readAsBytes());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error while copying file: $e')));
    }
  }

  Future<void> _saveStudentAndQrCode() async {
    // Saving student's data locally
    if (!widget.edit) {
      await gradeStorage.addStudent(widget.grade, widget.section, widget.student);
      print(!widget.edit);
    } else {
      await gradeStorage.editStudent(widget.grade, widget.section, widget.student);
      print(widget.edit);
    }

    // Saving photo
    if (widget.image != null && !widget.edit) {
      await saveImage(widget.image!, widget.student.name);
    }

    // Saving qr code to gallery
    // RenderRepaintBoundary? boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    // if (boundary != null) {
    //   var image = await boundary.toImage(pixelRatio: 3.0);
    //   ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);
    //   if (byteData != null) {
    //     try {
    //       await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
    //     } catch (e) {
    //       ScaffoldMessenger.of(context).showSnackBar(
    //         SnackBar(content: Text(e.toString())),
    //       );
    //     }
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('QR code saved to gallery')),
    //     );
        Navigator.pop(context);
        Navigator.pop(context); // also pop previous screen
    //   } else {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       const SnackBar(content: Text('Failed to save QR code')),
    //     );
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Student'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Grade: ${widget.grade.name}', style: const TextStyle(fontSize: 15.0),),
                          Text('Section: ${widget.section.name}', style: const TextStyle(fontSize: 15.0),),
                          Text('Student Name: ${widget.student.name}', style: const TextStyle(fontSize: 15.0),),
                          Text('LRN Number: ${widget.student.lrn}', style: const TextStyle(fontSize: 15.0),),
                          Text('Phone Number: ${widget.student.phNumber}', style: const TextStyle(fontSize: 15.0),),
                          Text('Gender: ${widget.student.gender}', style: const TextStyle(fontSize: 15.0),),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey,
                      backgroundImage: widget.image != null ? FileImage(widget.image!) : null,
                    ),
                  ],
                ),
                // const SizedBox(height: 20.0,),
                // Center(
                //   child: RepaintBoundary(
                //     key: _globalKey,
                //     child: QrImage(
                //       data: widget.codeData,
                //       version: QrVersions.auto,
                //       size: MediaQuery.of(context).orientation == Orientation.portrait?
                //         MediaQuery.of(context).size.width * 0.8 : MediaQuery.of(context).size.height * 0.6,
                //       backgroundColor: Colors.white,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 35.0,),
                MyButton(
                  onTap: _saveStudentAndQrCode,
                  // widget: const Text('Save Student and QR code'),
                  widget: const Text('Save Student Locally'),
                ),
                const SizedBox(height: 20.0,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
