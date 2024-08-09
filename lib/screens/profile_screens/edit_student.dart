import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tracked/models/grade_student.dart';
import 'package:tracked/screens/profile_screens/save_student_and_qrcode.dart';
import 'package:tracked/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart' as foundation;
import 'package:toggle_switch/toggle_switch.dart';
import '../../models/grade.dart';
import '../../models/section.dart';
import '../../utils/consts.dart';

class EditStudent extends StatefulWidget {
  final Grade grade;
  final Section section;
  final GradeStudent student;
  const EditStudent({foundation.Key? key, required this.grade, required this.section, required this.student}) : super(key: key);

  @override
  State<EditStudent> createState() => _EditStudentState();
}

class _EditStudentState extends State<EditStudent> {
  File? _imageFile;
  final _lrnTextController = TextEditingController();
  final _nameTextController = TextEditingController();
  final _phNumberTextController = TextEditingController();
  final _lrnFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _phNumberFocusNode = FocusNode();
  int _toggleLabelIndex = 0;


  void retrieveImage(String lrn) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final imagePath = '${appDirectory.path}/$lrn.jpg';

    final File imageFile = File(imagePath);
    _imageFile = await imageFile.exists()? imageFile : null;

    if (await imageFile.exists()) {
      _imageFile = imageFile;
    } else {
      _imageFile = null;
    }

    setState(() {});
  }

  @override
  void initState() {
    _lrnTextController.text = widget.student.lrn;
    _nameTextController.text = widget.student.name;
    _phNumberTextController.text = widget.student.phNumber;
    _toggleLabelIndex = widget.student.gender == 'M' ? 0 : 1;

    retrieveImage(widget.student.lrn);
    super.initState();
  }

  String _encryptCode(String codeData) {
    final key = encrypt.Key.fromBase64(base64.encode(sha256.convert(utf8.encode('TrackED_Encryption')).bytes));
    final iv = IV.fromLength(16);

    final encryptor = Encrypter(AES(key));

    final encrypted = encryptor.encrypt(codeData, iv: iv);
    return encrypted.base64;
  }

  void _addStudent() {
    final lrnText = _lrnTextController.text.trim();
    final nameText = _nameTextController.text.trim();
    final phNumberText = _phNumberTextController.text.trim();
    final genderText = _toggleLabelIndex == 0? 'M' : 'F';

    if (lrnText.isEmpty || nameText.isEmpty || phNumberText.isEmpty || genderText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields!')));
      return;
    }

    _lrnFocusNode.unfocus();
    _nameFocusNode.unfocus();
    _phNumberFocusNode.unfocus();

    GradeStudent student = GradeStudent(lrn: lrnText, name: nameText, gender: genderText, phNumber: phNumberText);

    // generate code for qr
    String gradeSectionText = '${widget.grade.name} - ${widget.section.name}';
    String codeData = '$lrnText,,$nameText,,$gradeSectionText,,$phNumberText,,$genderText';

    // encode qr code data
    String encryptedCodeData = _encryptCode(codeData);

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SaveStudentAndQrCode(codeData: encryptedCodeData, grade: widget.grade, section: widget.section, student: student, image: _imageFile, edit: true),
    ),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Student'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20.0,),
                CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.grey,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null ? const Icon(Icons.person, size: 75.0, color: Colors.black) : null,
                ),
                const SizedBox(height: 15.0,),
                TextField(
                  controller: _lrnTextController,
                  focusNode: _lrnFocusNode,
                  enabled: false,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder()
                  ),
                ),
                const SizedBox(height: 15.0,),
                TextField(
                  controller: _nameTextController,
                  focusNode: _nameFocusNode,
                  decoration: const InputDecoration(
                      hintText: 'Enter Full Name',
                      border: OutlineInputBorder()
                  ),
                ),
                const SizedBox(height: 15.0,),
                TextField(
                  controller: _phNumberTextController,
                  focusNode: _phNumberFocusNode,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      hintText: 'Enter Phone Number',
                      border: OutlineInputBorder()
                  ),
                ),
                const SizedBox(height: 15.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Gender', style: TextStyle(fontSize: 16.0),),
                    ToggleSwitch(
                      activeBgColor: MediaQuery.of(context).platformBrightness == Brightness.dark? [myColor] : [myLightColor!],
                      initialLabelIndex: _toggleLabelIndex,
                      labels: const ['Male', 'Female'],
                      radiusStyle: true,
                      cornerRadius: 20.0,
                      inactiveBgColor: (MediaQuery.of(context).platformBrightness == Brightness.light)? Colors.grey[300] : Colors.grey[900],
                      totalSwitches: 2,
                      onToggle: (index) {
                        setState(() {
                          _toggleLabelIndex = index!;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15.0,),
                MyButton(
                  onTap: _addStudent,
                  widget: const Text('Next'),
                ),
                const SizedBox(height: 75.0,),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
