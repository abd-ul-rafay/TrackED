import 'package:tracked/screens/settings_screens/manage_user.dart';
import 'package:tracked/screens/settings_screens/settings.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';

class DecideSettings extends StatefulWidget {
  final User user;
  const DecideSettings({Key? key, required this.user}) : super(key: key);

  @override
  State<DecideSettings> createState() => _DecideSettingsState();
}

class _DecideSettingsState extends State<DecideSettings> {
  @override
  Widget build(BuildContext context) {
    return widget.user.schoolID == 'superAdmin'
        ? SettingsPage(isSuperAdmin: (widget.user.schoolID == 'superAdmin'), role: widget.user.role,)
        : ManageUserScreen(isSuperAdmin: (widget.user.schoolID == 'superAdmin'), schoolName: widget.user.schoolName, schoolID: widget.user.schoolID,);
  }
}
