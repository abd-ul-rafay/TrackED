import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tracked/widgets/my_button.dart';
import '../../models/user.dart' as model;
import '../../services/notification_manager.dart';
import '../../utils/consts.dart';

class SettingsScreen extends StatefulWidget {
  final model.User user;
  const SettingsScreen({super.key, required this.user});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final inMsgTextController = TextEditingController();
  final outMsgTextController = TextEditingController();
  int toggleLabelIndex = 0;
  bool sendNotification = false;
  bool isCustomMessageSet = false;

  String teacherMsgPar1 = 'Student_name, ';
  String teacherMsgPar2 = 'Subject_name - Teacher_name. \nDate @ exactly Time - School_abbr.';
  String guardMsgPar1 = 'Student_name, ';
  String guardMsgPar2 = 'School_abbr. \nDate @ exactly Time.';
  String completeMsgIn = '';
  String completeMsgOut = '';

  @override
  void initState() {
    super.initState();
    _loadSendNotification();
    _loadCustomMessage();
  }

  Future<void> _loadSendNotification() async {
    bool sendNotification = await NotificationManager.getSendNotification();
    setState(() {
      toggleLabelIndex = sendNotification ? 1 : 0;
    });
  }

  Future<void> _saveSendNotification(int index) async {
    toggleLabelIndex = index;
    await NotificationManager.saveSendNotification(toggleLabelIndex);
    setState(() {
      sendNotification = toggleLabelIndex != 0;
    });
  }

  Future<void> _loadCustomMessage() async {
    Map<String, String>? customMessage = await NotificationManager.getCustomMessage();
    setState(() {
      isCustomMessageSet = customMessage != null;
      inMsgTextController.text = customMessage?['inText'] ?? '';
      outMsgTextController.text = customMessage?['outText'] ?? '';
      updateCompleteMsg();
    });
  }

  Future<void> _saveCustomMessage(String inText, String outText) async {
    isCustomMessageSet = true;
    await NotificationManager.saveCustomMessage(inText, outText);
    setState(() {
      updateCompleteMsg();
    });
  }

  void updateCompleteMsg() {
    completeMsgIn = widget.user.role == 'Guard'
        ? '$guardMsgPar1${inMsgTextController.text}$guardMsgPar2'
        : '$teacherMsgPar1${inMsgTextController.text}$teacherMsgPar2';

    completeMsgOut = widget.user.role == 'Guard'
        ? '$guardMsgPar1${outMsgTextController.text}$guardMsgPar2'
        : '$teacherMsgPar1${outMsgTextController.text}$teacherMsgPar2';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('You can enable or disable text notifications.'),
              const SizedBox(
                height: 10.0,
              ),
              ToggleSwitch(
                activeBgColor:
                    MediaQuery.of(context).platformBrightness == Brightness.dark
                        ? [myColor]
                        : [myLightColor!],
                initialLabelIndex: toggleLabelIndex,
                labels: const ['Disable', 'Enable'],
                radiusStyle: true,
                cornerRadius: 20.0,
                inactiveBgColor: (MediaQuery.of(context).platformBrightness ==
                        Brightness.light)
                    ? Colors.grey[300]
                    : Colors.grey[900],
                totalSwitches: 2,
                onToggle: (index) {
                    _saveSendNotification(index ?? 0);
                },
              ),
              const SizedBox(
                height: 20.0,
              ),
              toggleLabelIndex == 1
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Custom Notification for Time In:'),
                        TextField(
                          controller: inMsgTextController,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(
                          height: 10.0,
                        ),
                        const Text('Custom Notification for Time Out:'),
                        TextField(
                          controller: outMsgTextController,
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        MyButton(
                          onTap: () {
                            FocusScope.of(context).unfocus();

                            if (inMsgTextController.text.isEmpty || outMsgTextController.text.isEmpty) {
                              Fluttertoast.showToast(msg: "Fields are empty!",);
                              return;
                            }
                            _saveCustomMessage(inMsgTextController.text, outMsgTextController.text);
                            Fluttertoast.showToast(msg: "Custom notifications saved!",);
                          },
                          widget: const Text('Save Custom Notification'),
                        ),
                        const SizedBox(
                          height: 20.0,
                        ),
                        const Text('Complete Notification of Time In:'),
                        const SizedBox(
                          height: 3.0,
                        ),
                        Text(completeMsgIn),
                        const SizedBox(
                          height: 15.0,
                        ),
                        const Text('Complete Notification of Time Out:'),
                        const SizedBox(
                          height: 3.0,
                        ),
                        Text(completeMsgOut),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('No more text will be sent to the parents.'),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
