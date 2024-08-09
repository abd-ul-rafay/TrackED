// import 'dart:convert';
import 'dart:io';
// import 'package:encrypt/encrypt.dart';
// import 'package:encrypt/encrypt.dart' as encrypt;
// import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/foundation/key.dart' as foundation;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../models/grade.dart';
import '../../models/grade_student.dart';
import '../../models/section.dart';
import '../../services/grade_manager.dart';
import '../../services/notification_manager.dart';
import '../../utils/consts.dart';
import '../../models/Student.dart';
import 'package:tracked/models/user.dart' as model;
import '../../services/firestore.dart';
import '../../services/send_sms.dart';

class ScanPage extends StatefulWidget {
  final model.User user;
  const ScanPage({foundation.Key? key, required this.user,}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with SingleTickerProviderStateMixin {
  final _globalKey = GlobalKey();
  QRViewController? _controller;
  Barcode? _result;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _customTextController = TextEditingController();
  File? schoolImage;
  var sendNotificationEnabled = false;
  String customInText = '';
  String customOutText = '';

  final _items = [ // we will add teachers subject with it but first element will 'Select a Subject'
    'Select a Subject',
  ]; String _dropDownValue = 'Select a Subject';

  int _toggleLabelIndex = 0; // For toggle switch, 0 index (In), 1 index (Out)

  final List<Student> _todayReport = [];
  final List<Student> _todayReportForGuard = [];
  int _totalMales = 0, _totalFemales = 0;
  int _attendeesMale = 0, _attendeesFemale = 0, _absenteesMale = 0, _absenteesFemale = 0;

  GradeStorage gradeStorage = GradeStorage();
  List<Grade> grades = [];
  bool gradeListLoaded = false;

  void loadGrades() async {
    List<Grade> loadedGrades = await gradeStorage.getGrades();
    setState(() {
      grades = loadedGrades;
      gradeListLoaded = true;
    });
  }

  Map<String, String>? getStudentDataByName(String studentName, List<Grade> grades) {
    for (Grade grade in grades) {
      for (Section section in grade.sections) {
        for (GradeStudent student in section.students) {
          if (student.name == studentName) {
            return {'lrn': student.lrn, 'gradeSection': '${grade.name} - ${section.name}'};
          }
        }
      }
    }
    // Student not found
    return null;
  }

  List<String>? getDataFromString(String result,) {
    if (result.isEmpty) {
      return [];
    }

    List<String> parts = result.split(",,");
    // [lrn,,name,,gradeAndSection,,phoneNumber,,gender]
    // [name,,phoneNumber,,gender]

    // changed
    // if (parts.length != 5) {
    //   return null;
    // }

    // instead
    if (parts.length != 3) {
      return null;
    }

    return parts;
  }

  Future<void> checkSmsPermission() async {
    var status = await Permission.sms.status;
    if (status.isDenied) {
      await Permission.sms.request().then((value) {
        _controller?.pauseCamera();
        _controller?.resumeCamera();
      });
    }
  }

  Future<void> _loadCustomMessage() async {
    Map<String, String>? customMessage = await NotificationManager.getCustomMessage();
    setState(() {
      customInText = customMessage?['inText'] ?? '';
      customOutText = customMessage?['outText'] ?? '';
    });
  }

  void message(Student student) async {
    bool isMessageSent = true;
    await _loadSendNotification(); // check whether notification is turned on or not
    if (sendNotificationEnabled) {
      await checkSmsPermission();

      final currentDateTime = DateTime.now();
      final timeFormat = DateFormat('h:mm a').format(currentDateTime);
      final dateFormat = DateFormat('MM/dd/yyyy').format(currentDateTime);

      await _loadCustomMessage();

      String teacherMsg = '${student.name}, ${student.isIn? customInText : customOutText}${student.subject} - ${widget.user.name}. \n$dateFormat @ exactly $timeFormat - ${widget.user.schoolAbbr}.';
      String guardMsg = '${student.name}, ${student.isIn? customInText : customOutText}${widget.user.schoolAbbr}. \n$dateFormat @ exactly $timeFormat.';

      // final defaultMsg = widget.user.role != 'Guard'
      //     ? 'Your child ${student.name} is ${student.isIn? 'now attending' : 'now out in'} ${student.subject} class. \n$dateFormat @ exactly $timeFormat - ${widget.user.schoolAbbr}.'
      //     : 'Your child ${student.name} is ${student.isIn? 'now inside school premises.' : 'now outside school premises.'} \n$dateFormat @ exactly $timeFormat - ${widget.user.schoolAbbr}.';

      final defaultMsg = widget.user.role == 'Guard'
          ? guardMsg
          : teacherMsg;

      // if text-field text is not empty, send that text as message else send default message
      var messageText = _customTextController.text.trim().toString().isNotEmpty
          ? _customTextController.text.trim().toString()
          : defaultMsg;

      isMessageSent = await SmsService.message([student.phoneNo], messageText, context);
    }

    if (!isMessageSent) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please scan again!'), duration: Duration(milliseconds: 2000),)
      );
      return;
    }

    // Now we have to save this report to teacher's report list
    FirestoreService().saveReport(student, () {});

    setState(() {
      _animationController.forward();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
        content: ScaleTransition(
          scale: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 5.0,),
              const Icon(Icons.done, color: Colors.green, size: 150.0,),
              const SizedBox(height: 5.0,),
              Text(student.name, style: const TextStyle(fontSize: 18.0,), textAlign: TextAlign.center,),
              Visibility(
                visible: sendNotificationEnabled,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 3.0,),
                    Text('Message Sent', style: TextStyle(fontSize: 16.0,),),
                  ]
                ),
              ),
              const SizedBox(height: 10.0,),
            ],
          ),
        ),
      ),).then((value) {
        _controller?.resumeCamera();
      });

      Future.delayed(const Duration(milliseconds: 1200), () {
        Navigator.of(context).pop();
        _controller?.resumeCamera();
      });
    });
  }

  // String _decryptCode(String code) {
  //   try {
  //     final key = encrypt.Key.fromBase64(base64.encode(sha256.convert(utf8.encode('TrackED_Encryption')).bytes));
  //     final iv = IV.fromLength(16);
  //
  //     final encryptor = Encrypter(AES(key));
  //
  //     final encrypted = Encrypted.fromBase64(code);
  //     return encryptor.decrypt(encrypted, iv: iv);
  //   } catch(e) {
  //     showDialog(
  //       barrierDismissible: false,
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Padding(
  //           padding: const EdgeInsets.all(5.0),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: const [
  //               Text('Seems the format of QR code isn\'t correct', style: TextStyle(fontSize: 14,), textAlign: TextAlign.start,),
  //               SizedBox(height: 5.0,),
  //               Text('Please contact School Administrator for Assistance', style: TextStyle(fontSize: 14), textAlign: TextAlign.start,),
  //               SizedBox(height: 5.0,),
  //             ],
  //           ),
  //         ),
  //         icon: const Icon(Icons.error, color: myColor,),
  //       ),).then((value) {
  //       _controller?.resumeCamera();
  //     });
  //
  //     Future.delayed(const Duration(milliseconds: 1500), () {
  //       Navigator.of(context).pop();
  //       _controller?.resumeCamera();
  //     });
  //   }
  //
  //   return '';
  // }

  void sendMessage() {
    // If subject is not chosen, dropDownValue is 'Select a Subject',
    // also we have to check if it is not guard, because guard don't have subjects feature
    if (_dropDownValue == _items[0] && widget.user.role != 'Guard') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Select any Subject'),
          icon: Icon(Icons.error, color: myColor,),
      ),).then((value) {
          // press button, shut keyboard
          if (!FocusScope.of(context).hasPrimaryFocus) {
            FocusScope.of(context).unfocus();
          }
          _controller?.resumeCamera();
      });

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pop();
        _controller?.resumeCamera();
      });

      return;
    }

    // changed
    // String decryptedCode = _decryptCode(_result!.code.toString());
    // List<String>? parts = getDataFromString(decryptedCode);

    // instead
    List<String>? parts = getDataFromString(_result!.code.toString());

    if (parts != null) {

      // changed
      // final studentLrn = parts[0];
      // final studentName = parts[1];
      // final studentGradeSection = parts[2];
      // final studentPhoneNumber = parts[3];
      // final studentGender = parts[4];
      //
      // final student = Student(
      //   name: studentName,
      //   lrn: studentLrn,
      //   gradeSection: studentGradeSection,
      //   phoneNo: studentPhoneNumber,
      //   gender: studentGender,
      //   subject: widget.user.role == 'Guard'? '' : _dropDownValue,
      //   date: DateTime.now(),
      //   isIn: (_toggleLabelIndex == 0) ? true : false,
      // );

      // To avoid multi scan same student, we will first check isn't same user
      // Also we checked if custom text box is empty (not typed) then avoid multi scan (requirement)

      var studentReturnedData = getStudentDataByName(parts[0], grades);
      var studentLrn;
      var studentGradeSection;

      if (studentReturnedData != null) {
        studentLrn = studentReturnedData!['lrn'];
        studentGradeSection = studentReturnedData['gradeSection'];
      } else {
        studentLrn = 'None';
        studentGradeSection = 'None';
      }

      // instead
      final studentName = parts[0];
      final studentPhoneNumber = parts[1];
      final studentGender = parts[2];

      final student = Student(
        name: studentName,
        lrn: studentLrn,
        gradeSection: studentGradeSection,
        phoneNo: studentPhoneNumber,
        gender: studentGender,
        subject: widget.user.role == 'Guard'? '' : _dropDownValue,
        date: DateTime.now(),
        isIn: (_toggleLabelIndex == 0) ? true : false,
      );

      if (widget.user.studentsReport.isNotEmpty && _customTextController.text.trim().toString().isEmpty) {
        for (var report in widget.user.studentsReport) {
          if (student.name == report.name
              && student.date.day == report.date.day && student.date.month == report.date.month && student.date.year == report.date.year
              && student.date.difference(report.date).inMinutes <= 15 // means after 15 minutes, we can scan again
              && student.subject == report.subject && student.isIn == report.isIn && student.gender == report.gender) {

            _controller?.pauseCamera();

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
              const AlertDialog(
                title: Text('Student Already Scanned!'),
                content: Text('Please scan next QR code'),
                icon: Icon(Icons.error, color: myColor,),
              ),).then((value) {
              _controller?.resumeCamera();
            });

            Future.delayed(const Duration(milliseconds: 1500), () {
              Navigator.of(context).pop();
              _controller?.resumeCamera();
            });

            return; // no need to go further
          }
        }
      }

      if (!FocusScope.of(context).hasPrimaryFocus) {
        FocusScope.of(context).unfocus();
      }

      message(student);

    } else {

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => const AlertDialog(
          title: Padding(
            padding: EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seems the format of QR code isn\'t correct', style: TextStyle(fontSize: 14,), textAlign: TextAlign.start,),
                SizedBox(height: 5.0,),
                Text('Please contact School Administrator for Assistance', style: TextStyle(fontSize: 14), textAlign: TextAlign.start,),
                SizedBox(height: 5.0,),
              ],
            ),
          ),
          icon: const Icon(Icons.error, color: myColor,),
      ),).then((value) {
        _controller?.resumeCamera();
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.of(context).pop();
        _controller?.resumeCamera();
      });

    }
  }

  void checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  void qr(QRViewController controller) async {
    checkCameraPermission();

    _controller = controller;
    try {
      await controller.resumeCamera();
      controller.scannedDataStream.listen((event) {
        setState(() {
          _result = event;
          controller.pauseCamera(); // show that scanner stop scanning in background, we will resume after message sent
          sendMessage();
        });
      });
    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _loadSendNotification() async {
    sendNotificationEnabled = await NotificationManager.getSendNotification();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _showWifiWarning() {
    Fluttertoast.showToast(
      msg: 'Please Turn off Your Wi-Fi or Data Connection for Better Scanning!',
    );
  }

  @override
  void initState() {
    super.initState();

    _showWifiWarning();

    _items.addAll(widget.user.subjects.map((subject) => subject.name).toList());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animationController.reset();
        });
      }
    });

    readProfilePhoto();

    if (widget.user.role == 'Guard') {
      loadGrades();
    }
  }

  void getTodayReport() {
    _todayReport.clear();
    _attendeesMale = _attendeesFemale = _absenteesMale = _absenteesFemale = 0;

    if (_dropDownValue == _items[0] && widget.user.role != 'Guard') {
      return;
    }

    if (widget.user.role == 'Guard') {
      _dropDownValue = '';
    }

    final todayDate = DateTime.now();

    for (var i in widget.user.studentsReport) {
      if (i.date.day == todayDate.day && i.date.month == todayDate.month && i.date.year == todayDate.year && i.isIn && i.subject == _dropDownValue) {

        _todayReport.add(i);
      }
    }

    // we have to now filter out (distinct) those student how are scanned multiply using custom text
    List<Student> todayReportDistinct = _todayReport.toSet().toList();

    for (var i in todayReportDistinct) {
      if (i.gender == 'M') {
        _attendeesMale += 1;
      } else if (i.gender == 'F') {
        _attendeesFemale += 1;
      }
    }

    var currentSubject = widget.user.subjects.where((subject) => subject.name == (widget.user.role == 'Guard'? '' : _dropDownValue)).toList().first;

    _absenteesMale = int.parse(currentSubject.noOfMale) - _attendeesMale; // total - present
    _absenteesFemale = int.parse(currentSubject.noOfFemale) - _attendeesFemale;

    _totalMales = int.parse(currentSubject.noOfMale);
    _totalFemales = int.parse(currentSubject.noOfFemale);

  }

  Future<File?> retrieveImage(String lrnNumber) async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/$lrnNumber.jpg';
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    } else {
      return null;
    }
  }

  List<Student> todayReportForGuard() {
    final todayDate = DateTime.now();

    for (var i in widget.user.studentsReport) {
      if (i.date.day == todayDate.day && i.date.month == todayDate.month && i.date.year == todayDate.year) {
        _todayReportForGuard.add(i);
      }
    }

    // we have to now filter out (distinct) those student how are scanned multiply using custom text
    List<Student> todayReportGuardDistinct = _todayReportForGuard.toSet().toList();
    todayReportGuardDistinct.sort((a, b) => b.date.compareTo(a.date)); // sorting so that latest date come first...

    final startingReport = <Student>[];
    startingReport.addAll(todayReportGuardDistinct.take(5).toList());

    return startingReport;
  }

  void saveProfilePhoto() {

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Upload School Logo'),
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
                  Fluttertoast.showToast(msg: 'Not able to upload logo');
                  return;
                }

                final appDirectory = await getApplicationDocumentsDirectory();
                final imagePath = '${appDirectory.path}/school_photo.png';

                final File imageFile = File(imagePath);

                if (await imageFile.exists()) {
                  await imageFile.delete();
                }

                await imageFile.writeAsBytes(await image.readAsBytes()).then((value) {
                  setState(() {
                    schoolImage = File(image.path);
                    setState((){ });
                  });
                });

              } on PlatformException catch(e) {
                Fluttertoast.showToast(msg: e.toString());
              }
            },
            child: const Text('Open Gallery')
        ),
        Visibility(
          visible: schoolImage != null,
          child: TextButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  final appDirectory = await getApplicationDocumentsDirectory();
                  final imagePath = '${appDirectory.path}/school_photo.png';
                  final imageFile = File(imagePath);

                  if (await imageFile.exists()) {
                    await imageFile.delete();
                    Fluttertoast.showToast(msg: 'Logo removed successfully');
                  }

                  schoolImage = null;
                  setState(() { });

                } catch (e) {
                  Fluttertoast.showToast(msg: 'Error removing logo: $e');
                }
              },
              child: const Text('Remove Logo')
          ),
        ),
      ],
    ),);
  }

  void readProfilePhoto() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final imagePath = '${appDirectory.path}/school_photo.png';

    final File imageFile = File(imagePath);
    schoolImage = await imageFile.exists()? imageFile : null;

    if (await imageFile.exists()) {
      schoolImage = imageFile;
    } else {
      schoolImage = null;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    getTodayReport();

    final deviceWidth = MediaQuery.of(context).size.shortestSide;
    final isTablet = deviceWidth > 600;

    return Scaffold(
      body: widget.user.role == 'Guard'
          ? isTablet
          ? MediaQuery.of(context).orientation == Orientation.portrait
          ? guardTabPortraitUI()
          : guardTabLandscapeUI()
          : guardMobileUI()
          : teacherUI(),
    );
  }

  Widget teacherUI() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10.0,),
              Row(
                mainAxisAlignment: (widget.user.role == 'Guard')? MainAxisAlignment.center : MainAxisAlignment.spaceAround,
                children: [
                  // if is guard, we don't need to show him subject dropdown...
                  widget.user.role == 'Guard'
                    ? const SizedBox()
                    : DropdownButton(
                    value: _dropDownValue,
                    icon: const Icon(Icons.arrow_downward_rounded, color: myColor,),
                    items: _items.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: Text(items, style: const TextStyle(color: myColor), maxLines: 1, overflow: TextOverflow.ellipsis,),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _dropDownValue = newValue!;
                      });
                    },
                  ),
                  ToggleSwitch(
                    activeBgColor: MediaQuery.of(context).platformBrightness == Brightness.dark? [myColor] : [myLightColor!],
                    initialLabelIndex: _toggleLabelIndex,
                    labels: const ['In', 'Out'],
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
              (_dropDownValue == _items[0] && widget.user.role != 'Guard')
                ? const SizedBox()
                : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  child: Text('Total Males: $_totalMales',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5.0,),
                            const Text('Attendees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                            Text('Male: $_attendeesMale | Female: $_attendeesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                          ],
                        ),
                        Container(
                          width: 1.0,
                          height: 60.0,
                          color: Colors.grey,
                        ),// divider
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  child: Text('Total Females: $_totalFemales',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5.0,),
                            const Text('Absentees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),),
                            Text('Male: $_absenteesMale | Female: $_absenteesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25.0,),
              Stack(
                children: [
                  _buildQRView(context),
                  Positioned(
                    bottom: 10.0,
                    right: 10.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: myColor,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          await _controller?.flipCamera();
                        },
                        icon: const Icon(
                          Icons.cameraswitch_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15.0,),
              TextField(
                controller: _customTextController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                    label: const Text('Custom Text'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    )
                ),
              ),
              const SizedBox(height: 10.0,),
            ],
          ),
        ),
      ),
    );
  }

  Widget guardTabLandscapeUI() {
    final studentReport = todayReportForGuard();
    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // guardTopRow(18.0, isDarkTheme),
                const SizedBox(height: 10.0,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Scanner
                    Column(
                      children: [
                        Stack(
                          children: [
                            _buildGuardLandScapeQRView(context),
                            Positioned(
                              bottom: 10.0,
                              right: 10.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: myColor,
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    await _controller?.flipCamera();
                                  },
                                  icon: const Icon(
                                    Icons.cameraswitch_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        // const SizedBox(height: 5.0,),
                        // SizedBox(
                        //   width: MediaQuery.of(context).size.width * 0.35,
                        //   child: TextField(
                        //     controller: _customTextController,
                        //     keyboardType: TextInputType.multiline,
                        //     maxLines: null,
                        //     decoration: InputDecoration(
                        //         label: const Text('Custom Text'),
                        //         border: OutlineInputBorder(
                        //           borderRadius: BorderRadius.circular(5.0),
                        //         )
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 5.0,),
                        ToggleSwitch(
                          activeBgColor: MediaQuery.of(context).platformBrightness == Brightness.dark? [myColor] : [myLightColor!],
                          initialLabelIndex: _toggleLabelIndex,
                          labels: const ['In', 'Out'],
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
                        const SizedBox(height: 5.0,),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5.0,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.15,
                                              child: Text('Total Males: $_totalMales',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5.0,),
                                        const Text('Attendees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),),
                                        Text('Male: $_attendeesMale | Female: $_attendeesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),),
                                      ],
                                    ),
                                    Container(
                                      width: 1.0,
                                      height: 60.0,
                                      color: Colors.grey,
                                    ),// divider
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.15,
                                              child: Text('Total Females: $_totalFemales',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                                textAlign: TextAlign.start,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5.0,),
                                        const Text('Absentees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0,),),
                                        Text('Male: $_absenteesMale | Female: $_absenteesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // second portion
                    SizedBox(
                      child: Column(
                        children: [
                          // log report
                          const Text('Student Attendance Log Report', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 15.0),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.4,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: studentReport.isEmpty? const [
                                      Text('LRN Number:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Full Name:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - -   - - - -   - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Grade and Section:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - -   -   - - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Gender:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                    ] : [
                                      const Text('LRN Number:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].lrn}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Full Name:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].name}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Grade and Section:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].gradeSection}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Gender:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].gender == 'M' ? 'Male' : studentReport[0].gender == 'F' ? 'Female' : studentReport[0].gender}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1.0,
                                  height: 130.0,
                                  color: Colors.grey,
                                ),
                                Column(
                                  children: [
                                    studentReport.isEmpty
                                    ? Container(
                                      width: 150,
                                      height: 150,
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage('assets/images/launcher_icon.png'),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                    : FutureBuilder<File?>(
                                      future: retrieveImage(studentReport[0].name),
                                      builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          // While the image is being retrieved, you can show a placeholder or a loading indicator.
                                          return Container(
                                              width: 150,
                                              height: 150,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey, width: 1.0),
                                              ),
                                              child: const Center(
                                                child: Text('Loading...'),
                                              )
                                          );
                                        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                          // Handle the case where the image is not available
                                          return Container(
                                              width: 150,
                                              height: 150,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey, width: 1.0),
                                              ),
                                              child: const Center(
                                                child: Text('No Photo Found!'),
                                              )
                                          );
                                        } else {
                                          final imageFile = snapshot.data!;
                                          return Container(
                                            width: 150,
                                            height: 150,
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey, width: 1.0),
                                              image: DecorationImage(
                                                image: FileImage(imageFile),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 10.0,),
                                    Text(studentReport.isEmpty ? '- - - -   - -   - - - -' : DateFormat('MMMM d, y').format(studentReport[0].date), style: const TextStyle(fontSize: 16.0),),
                                    const SizedBox(height: 5.0,),
                                    Text(studentReport.isEmpty ? '- - : - - : - -   - -' : DateFormat.jms().format(studentReport[0].date), style: const TextStyle(fontSize: 16.0),),
                                  ],
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 1.0,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 30.0),
                          // last five reports
                          const Text('Last Scanned Reports', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 15.0),
                          Table(
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            border: TableBorder.symmetric(inside: BorderSide(width: 1, color: isDarkTheme? Colors.white12 : Colors.blue.withOpacity(0.3)),),
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: IntrinsicColumnWidth(),
                              2: IntrinsicColumnWidth(),
                              3: IntrinsicColumnWidth(),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                    color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                    child: const Text(
                                      'Full Name',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                      color: isDarkTheme? tableColorForDark : tableColor,
                                      child: const Text('Grade and Section',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                      color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                      child: const Text('TimeIn',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                  Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                      color: isDarkTheme? tableColorForDark : tableColor,
                                      child: const Text('TimeOut',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                ]
                            ),

                              for (Student i in studentReport)
                                TableRow(
                                  children: [
                                    Container(
                                        width: 200.0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: Text(i.name, style: const TextStyle(fontSize: 14.0), textAlign: TextAlign.start,  overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: 200.0,
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: Text(i.gradeSection, style: const TextStyle(fontSize: 14.0), textAlign: TextAlign.start, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: Text(i.isIn? DateFormat.jm().format(i.date) : '- - -', style: const TextStyle(fontSize: 14.0), textAlign: i.isIn? TextAlign.start : TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: Text(i.isIn? '- - -' : DateFormat.jm().format(i.date), style: const TextStyle(fontSize: 14.0), textAlign: i.isIn? TextAlign.center : TextAlign.start, overflow: TextOverflow.ellipsis,)
                                    ),
                                  ]
                              ),

                              // we will now show empty rows if list has less than 5 elements
                              for (int i = 0; i < (5 - studentReport.length); i++)
                                TableRow(
                                  children: [
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center,  overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                  ]
                              ),
                            ],
                          ),
                          const SizedBox(height: 15.0),
                          Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()), style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, letterSpacing: 1,), textAlign: TextAlign.center,),
                          const SizedBox(height: 35.0),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget guardTabPortraitUI() {
    final studentReport = todayReportForGuard();
    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0,),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // guardTopRow(18.0, isDarkTheme),
                const SizedBox(height: 20.0,),
                Column(
                  children: [
                    // Scanner
                    Column(
                      children: [
                        Stack(
                          children: [
                            _buildQRView(context),
                            Positioned(
                              bottom: 10.0,
                              right: 10.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: myColor,
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    await _controller?.flipCamera();
                                  },
                                  icon: const Icon(
                                    Icons.cameraswitch_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 15.0,),
                        // SizedBox(
                        //   child: TextField(
                        //     controller: _customTextController,
                        //     keyboardType: TextInputType.multiline,
                        //     maxLines: null,
                        //     decoration: InputDecoration(
                        //         label: const Text('Custom Text'),
                        //         border: OutlineInputBorder(
                        //           borderRadius: BorderRadius.circular(5.0),
                        //         )
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 10.0,),
                        ToggleSwitch(
                          activeBgColor: MediaQuery.of(context).platformBrightness == Brightness.dark? [myColor] : [myLightColor!],
                          initialLabelIndex: _toggleLabelIndex,
                          labels: const ['In', 'Out'],
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
                        const SizedBox(height: 15.0,),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5.0,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.15,
                                              child: Text('Total Males: $_totalMales',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5.0,),
                                        const Text('Attendees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),),
                                        Text('Male: $_attendeesMale | Female: $_attendeesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),),
                                      ],
                                    ),
                                    Container(
                                      width: 1.0,
                                      height: 60.0,
                                      color: Colors.grey,
                                    ),// divider
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.15,
                                              child: Text('Total Females: $_totalFemales',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                                textAlign: TextAlign.start,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5.0,),
                                        const Text('Absentees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0,),),
                                        Text('Male: $_absenteesMale | Female: $_absenteesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // second portion
                    const SizedBox(height: 25.0,),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 1.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 15.0,),
                    SizedBox(
                      child: Column(
                        children: [
                          // log report
                          const Text('Student Attendance Log Report', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 15.0),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: studentReport.isEmpty? const [
                                      Text('LRN Number:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Full Name:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - -   - - - -   - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Grade and Section:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - -   -   - - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Gender:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - -', style: TextStyle(fontSize: 16.0,),),
                                      SizedBox(height: 5.0,),
                                    ] : [
                                      const Text('LRN Number:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].lrn}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Full Name:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].name}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Grade and Section:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].gradeSection}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Gender:', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].gender == 'M' ? 'Male' : studentReport[0].gender == 'F' ? 'Female' : studentReport[0].gender}', style: const TextStyle(fontSize: 16.0,),),
                                      const SizedBox(height: 5.0,),
                                    ],
                                  ),
                                  Container(
                                    width: 1.0,
                                    height: 160.0,
                                    color: Colors.grey,
                                  ),
                                  Column(
                                    children: [
                                      studentReport.isEmpty
                                      ? Container(
                                        width: 150,
                                        height: 150,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/images/launcher_icon.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                      : FutureBuilder<File?>(
                                        future: retrieveImage(studentReport[0].name),
                                        builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            // While the image is being retrieved, you can show a placeholder or a loading indicator.
                                            return Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey, width: 1.0),
                                                ),
                                                child: const Center(
                                                  child: Text('Loading...'),
                                                )
                                            );
                                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                            // Handle the case where the image is not available
                                            return Container(
                                                width: 150,
                                                height: 150,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey, width: 1.0),
                                                ),
                                                child: const Center(
                                                  child: Text('No Photo Found!'),
                                                )
                                            );
                                          } else {
                                            final imageFile = snapshot.data!;
                                            return Container(
                                              width: 150,
                                              height: 150,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey, width: 1.0),
                                                image: DecorationImage(
                                                  image: FileImage(imageFile),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 10.0,),
                                      Text(studentReport.isEmpty ? '- - - -   - -   - - - -' : DateFormat('MMMM d, y').format(studentReport[0].date), style: const TextStyle(fontSize: 16.0),),
                                      const SizedBox(height: 5.0,),
                                      Text(studentReport.isEmpty ? '- - : - - : - -   - -' : DateFormat.jms().format(studentReport[0].date), style: const TextStyle(fontSize: 16.0),),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 1.0,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 30.0),
                          // last five reports
                          const Text('Last Scanned Reports', style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 15.0),
                          Table(
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            border: TableBorder.symmetric(inside: BorderSide(width: 1, color: isDarkTheme? Colors.white12 : Colors.blue.withOpacity(0.3)),),
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: IntrinsicColumnWidth(),
                              2: IntrinsicColumnWidth(),
                              3: IntrinsicColumnWidth(),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.32,
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                    color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                    child: const Text(
                                      'Full Name',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width * 0.28,
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                      color: isDarkTheme? tableColorForDark : tableColor,
                                      child: const Text('Grade and Section',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width * 0.15,
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                      color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                      child: const Text('TimeIn',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width * 0.15,
                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                      color: isDarkTheme? tableColorForDark : tableColor,
                                      child: const Text('TimeOut',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                ]
                            ),

                              for (Student i in studentReport)
                                TableRow(
                                  children: [
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.32,
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: Text(i.name, style: const TextStyle(fontSize: 14.0), textAlign: TextAlign.center,  overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.28,
                                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: Text(i.gradeSection, style: const TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.15,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: Text(i.isIn? DateFormat.jm().format(i.date) : '- - -', style: const TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.15,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: Text(i.isIn? '- - -' : DateFormat.jm().format(i.date), style: const TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                  ]
                              ),

                              // we will now show empty rows if list has less than 5 elements
                              for (int i = 0; i < (5 - studentReport.length); i++)
                                TableRow(
                                  children: [
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.32,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center,  overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.28,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.15,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.15,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: const Text('- - -', style: TextStyle(fontSize: 14.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                  ]
                              ),
                            ],
                          ),
                          const SizedBox(height: 15.0),
                          Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()), style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, letterSpacing: 1,), textAlign: TextAlign.center,),
                          const SizedBox(height: 35.0),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget guardMobileUI() {
    final studentReport = todayReportForGuard();
    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 15.0,),
                Column(
                  children: [
                    // guardTopRow(14.0, isDarkTheme),
                    const SizedBox(height: 10.0,),
                    // Scanner
                    Column(
                      children: [
                        Stack(
                          children: [
                            _buildQRView(context),
                            Positioned(
                              bottom: 10.0,
                              right: 10.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: myColor,
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    await _controller?.flipCamera();
                                  },
                                  icon: const Icon(
                                    Icons.cameraswitch_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 10.0,),
                        // TextField(
                        //   controller: _customTextController,
                        //   keyboardType: TextInputType.multiline,
                        //   maxLines: null,
                        //   decoration: InputDecoration(
                        //       label: const Text('Custom Text'),
                        //       border: OutlineInputBorder(
                        //         borderRadius: BorderRadius.circular(5.0),
                        //       )
                        //   ),
                        // ),
                        // const SizedBox(height: 5.0,),
                        ToggleSwitch(
                          activeBgColor: MediaQuery.of(context).platformBrightness == Brightness.dark? [myColor] : [myLightColor!],
                          initialLabelIndex: _toggleLabelIndex,
                          labels: const ['In', 'Out'],
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
                        const SizedBox(height: 10.0,),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5.0,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context).size.width * 0.4,
                                            child: Text('Total Males: $_totalMales',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5.0,),
                                      const Text('Attendees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                                      Text('Male: $_attendeesMale | Female: $_attendeesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                                    ],
                                  ),
                                  Container(
                                    width: 1.0,
                                    height: 60.0,
                                    color: Colors.grey,
                                  ),// divider
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: MediaQuery.of(context).size.width * 0.4,
                                            child: Text('Total Females: $_totalFemales',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                              textAlign: TextAlign.start,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5.0,),
                                      const Text('Absentees:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),),
                                      Text('Male: $_absenteesMale | Female: $_absenteesFemale', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 15.0,
                    ),
                    SizedBox(
                      child: Column(
                        children: [
                          // log report
                          const Text('Student Attendance Log Report', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 15.0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: studentReport.isEmpty? const [
                                      Text('LRN Number:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - - - -', style: TextStyle(fontSize: 14.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Full Name:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - -   - - - -   - - - - -', style: TextStyle(fontSize: 14.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Grade and Section:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - -   -   - - - - - -', style: TextStyle(fontSize: 14.0,),),
                                      SizedBox(height: 5.0,),
                                      Text('Gender:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      SizedBox(height: 5.0,),
                                      Text('\t\t- - - - - - -', style: TextStyle(fontSize: 14.0,),),
                                      SizedBox(height: 5.0,),
                                    ] : [
                                      const Text('LRN Number:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].lrn}', style: const TextStyle(fontSize: 14.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Full Name:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].name}', style: const TextStyle(fontSize: 14.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Grade and Section:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].gradeSection}', style: const TextStyle(fontSize: 14.0,),),
                                      const SizedBox(height: 5.0,),
                                      const Text('Gender:', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),),
                                      const SizedBox(height: 5.0,),
                                      Text('\t\t${studentReport[0].gender == 'M' ? 'Male' : studentReport[0].gender == 'F' ? 'Female' : studentReport[0].gender}', style: const TextStyle(fontSize: 14.0,),),
                                      const SizedBox(height: 5.0,),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1.0,
                                  height: 130.0,
                                  color: Colors.grey,
                                ),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      studentReport.isEmpty
                                      ? Container(
                                        width: 100,
                                        height: 100,
                                        decoration: const BoxDecoration(
                                          image: DecorationImage(
                                            image: AssetImage('assets/images/launcher_icon.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                      : FutureBuilder<File?>(
                                        future: retrieveImage(studentReport[0].name),
                                        builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            // While the image is being retrieved, you can show a placeholder or a loading indicator.
                                            return Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey, width: 1.0),
                                                ),
                                                child: const Center(
                                                  child: Text('Loading...'),
                                                )
                                            );
                                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                                            // Handle the case where the image is not available
                                            return Container(
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey, width: 1.0),
                                                ),
                                                child: const Center(
                                                  child: Text('No Photo Found!', textAlign: TextAlign.center,),
                                                )
                                            );
                                          } else {
                                            final imageFile = snapshot.data!;
                                            return Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey, width: 1.0),
                                                image: DecorationImage(
                                                  image: FileImage(imageFile),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 10.0,),
                                      Text(studentReport.isEmpty ? '- - - -   - -   - - - -' : DateFormat('MMMM d, y').format(studentReport[0].date), style: const TextStyle(fontSize: 14.0),),
                                      const SizedBox(height: 5.0,),
                                      Text(studentReport.isEmpty ? '- - : - - : - -   - -' : DateFormat.jms().format(studentReport[0].date), style: const TextStyle(fontSize: 14.0),),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30.0),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 1.0,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 30.0),
                          // last five reports
                          const Text('Last Scanned Reports', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 15.0),
                          Table(
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            border: TableBorder.symmetric(inside: BorderSide(width: 1, color: isDarkTheme? Colors.white12 : Colors.blue.withOpacity(0.3)),),
                            columnWidths: const {
                              0: IntrinsicColumnWidth(),
                              1: IntrinsicColumnWidth(),
                              2: IntrinsicColumnWidth(),
                              3: IntrinsicColumnWidth(),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Container(
                                    width: MediaQuery.of(context).size.width * 0.28,
                                    padding: const EdgeInsets.all(5.0),
                                    color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                    child: const Text(
                                      'Full Name',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width * 0.28,
                                      padding: const EdgeInsets.all(5.0),
                                      color: isDarkTheme? tableColorForDark : tableColor,
                                      child: const Text('Grade and Section',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width * 0.2,
                                      padding: const EdgeInsets.all(5.0),
                                      color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                      child: const Text('TimeIn',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                  Container(
                                      width: MediaQuery.of(context).size.width * 0.2,
                                      padding: const EdgeInsets.all(5.0),
                                      color: isDarkTheme? tableColorForDark : tableColor,
                                      child: const Text('TimeOut',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      )
                                  ),
                                ]
                            ),

                              for (Student i in studentReport)
                                TableRow(
                                  children: [
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.28,
                                        padding: const EdgeInsets.all(5.0),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: Text(i.name, style: const TextStyle(fontSize: 12.0), textAlign: TextAlign.center,  overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.28,
                                        padding: const EdgeInsets.all(5.0),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: Text(i.gradeSection, style: const TextStyle(fontSize: 12.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        padding: const EdgeInsets.all(5.0),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: Text(i.isIn? DateFormat.jm().format(i.date) : '- - -', style: const TextStyle(fontSize: 12.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        padding: const EdgeInsets.all(5.0),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: Text(i.isIn? '- - -' : DateFormat.jm().format(i.date), style: const TextStyle(fontSize: 12.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                  ]
                              ),

                              // we will now show empty rows if list has less than 5 elements
                              for (int i = 0; i < (5 - studentReport.length); i++)
                                TableRow(
                                  children: [
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.28,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: const Text('- - -', style: TextStyle(fontSize: 12.0), textAlign: TextAlign.center,  overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.28,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: const Text('- - -', style: TextStyle(fontSize: 12.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                                        child: const Text('- - -', style: TextStyle(fontSize: 12.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                    Container(
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0,),
                                        color: isDarkTheme? tableColorForDark : tableColor,
                                        child: const Text('- - -', style: TextStyle(fontSize: 12.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                                    ),
                                  ]
                              ),
                            ],
                          ),
                          const SizedBox(height: 15.0),
                          Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()), style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, letterSpacing: 1,), textAlign: TextAlign.center,),
                          const SizedBox(height: 35.0),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget guardTopRow(double fontSize, bool isDarkTheme) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: saveProfilePhoto,
            child: CircleAvatar(
              radius: 30.0,
              backgroundColor: isDarkTheme ? Colors.white12 : Colors.black12,
              backgroundImage: schoolImage == null? null : FileImage(schoolImage!,),
            ),
          ),
          const SizedBox(width: 20.0,),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.schoolName, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 1,),),
                Text(widget.user.schoolAddress, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, letterSpacing: 1,),),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? (MediaQuery.of(context).size.width < 300 ||
            MediaQuery.of(context).size.height < 300)
            ? 150.0 : 250.0
        : 300.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        return Container(
          width: width,
          height: width,
          decoration: BoxDecoration(
            border: Border.all(color: myColor, width: 2.0,),
          ),
          child: QRView(
            key: _globalKey,
            onQRViewCreated: qr,
            overlay: QrScannerOverlayShape(
              borderColor: myColor,
              borderWidth: 5,
              cutOutSize: scanArea,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuardLandScapeQRView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? (MediaQuery.of(context).size.width < 300 ||
            MediaQuery.of(context).size.height < 300)
            ? 200.0 : 300.0
        : 350.0;

    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: BoxDecoration(
        border: Border.all(color: myColor, width: 2.0,),
      ),
      child: QRView(
        key: _globalKey,
        onQRViewCreated: qr,
        overlay: QrScannerOverlayShape(
          borderColor: myColor,
          borderWidth: 5,
          cutOutSize: scanArea,
        ),
      ),
    );
  }
}
