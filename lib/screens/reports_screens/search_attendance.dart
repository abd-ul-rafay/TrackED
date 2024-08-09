import 'dart:io';
import 'package:tracked/services/firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../utils/consts.dart';
import '../../models/Student.dart';
import 'package:tracked/models/user.dart' as model;
import 'package:intl/intl.dart';

class SearchAttendanceScreen extends StatefulWidget {
  final model.User user;
  const SearchAttendanceScreen({Key? key, required this.user,}) : super(key: key);

  @override
  State<SearchAttendanceScreen> createState() => _SearchAttendanceScreenState();
}

class _SearchAttendanceScreenState extends State<SearchAttendanceScreen> {

  final searchNameTextController = TextEditingController();
  final searchGradeSectionTextController = TextEditingController();

  var subjectsItems = [
    'Select a Subject',
  ]; String dropDownValue = 'Select a Subject';

  var fromDateController = TextEditingController(text: 'Select Date');
  var toDateController = TextEditingController(text: 'Select Date');

  DateTime fromDate = DateTime(2022, 1, 1), toDate = DateTime(2030, 1, 1);

  int toggleLabelIndex = 2;

  @override
  void initState() {
    super.initState();
    subjectsItems.addAll(widget.user.subjects.map((subject) => subject.name).toList());
  }

  void exportToExcel(List<Student> students,) async {

    if (students.isEmpty) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('No student report to export!'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    try {
      Excel excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      sheetObject.setColWidth(0, 22);
      sheetObject.setColWidth(1, 18);
      sheetObject.setColWidth(2, 22);
      sheetObject.setColWidth(4, 18);

      sheetObject.cell(CellIndex.indexByString("A1")).value = 'Name';
      sheetObject.cell(CellIndex.indexByString("B1")).value = widget.user.role == 'Guard'? 'School premises' : 'Subject';
      sheetObject.cell(CellIndex.indexByString("C1")).value = 'Grade and Section';
      sheetObject.cell(CellIndex.indexByString("D1")).value = 'Phone No';
      sheetObject.cell(CellIndex.indexByString("E1")).value = 'Date';
      sheetObject.cell(CellIndex.indexByString("F1")).value = 'Sex';
      sheetObject.cell(CellIndex.indexByString("G1")).value = 'Status';

      int rowIndex = 2;

      for (Student student in students) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = student.name;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = widget.user.role == 'Guard'? student.isIn ? 'Inside' : 'Outside' : student.subject; // subject in case role isn't Guard
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = student.gradeSection;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = student.phoneNo;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = student.date.toString();
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = student.gender;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = student.isIn ? 'In' : 'Out';
        rowIndex++;
      }

      String timestamp = DateFormat('HH-mm-ss-dd-MM-yyyy').format(DateTime.now());

      final String? path = await _getSavePath('Attendance-$timestamp');
      final excelData = excel.encode();
      if (path != null) {
        await File(path).writeAsBytes(excelData!).then((value) =>
        {
          showDialog(context: context, builder: (context) =>
              AlertDialog(
                icon: const Icon(Icons.save, color: myColor),
                title: const Text('Report Exported'),
                content: SelectableText(value.toString()),
                actions: [
                  GestureDetector(
                    onTap: ()=> Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          color: myLightColor,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: const Center(child: Text('Ok', style: TextStyle(color: Colors.white, fontSize: 16.0,),),),
                      ),
                    ),
                  ),
                ],
              ),)
        });
      }
    } catch(e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  Future<String?> _getSavePath(String fileName) async {

    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      final path = '$result/$fileName.xlsx';
      return path;
    }
    return null;
  }

  List<Student> getFilteredList() {
    List<Student> filteredList = [];

    for (Student i in widget.user.studentsReport) {
      if (
      ((toggleLabelIndex == 0 && i.isIn) || (toggleLabelIndex == 1 && !i.isIn) || (toggleLabelIndex == 2)) // filter in/out/both
          && ((i.subject == dropDownValue) || (dropDownValue == subjectsItems[0])) // filter subjects
          &&  (!i.date.isBefore(fromDate) && !i.date.isAfter(toDate)) // filter date
      ) {
        filteredList.add(i);
      }
    }

    filteredList.sort((a, b) => b.date.compareTo(a.date)); // sorting so that latest date come first...

    // filtering according to searched name or gradeSection
    final searchedFilteredList = filteredList.where((student) =>
        student.name.toLowerCase().contains(searchNameTextController.text.toLowerCase())
        && student.gradeSection.toLowerCase().contains(searchGradeSectionTextController.text.toLowerCase())
    ).toList();

    return searchedFilteredList;
  }

  void deleteAllReports() {
    if (widget.user.studentsReport.isEmpty) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('No student report to delete!'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete all reports', style: TextStyle(fontSize: 16.0),),
      actions: [
        TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancel'),),
        TextButton(onPressed: () {
          // Another dialog box
          showDialog(context: context, builder: (context) => AlertDialog(
            title: const Text('Are you sure, you want to delete all reports', style: TextStyle(fontSize: 16.0),),
            actions: [
              TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancel'),),
              TextButton(onPressed: () {
                Navigator.pop(context);
                FirestoreService().deleteAllReports()
                    .then((value) => setState(() { widget.user.studentsReport.clear(); }));
              }, child: const Text('Delete'),),
            ],
          ),).then((value) => Navigator.pop(context));

        }, child: const Text('Delete'),),
      ],
    ),);
  }

  @override
  Widget build(BuildContext context) {

    // we have to get filtered list of students (filter like date, in/out or subject)
    final filteredList = getFilteredList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Attendance',),
      ),
      body: SafeArea(
        child: CustomScrollView(
          // physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 5.0,),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        widget.user.role == 'Guard'
                        ? const SizedBox(width: 120,)
                        : DropdownButton(
                          value: dropDownValue,
                          icon: const Icon(Icons.arrow_downward_rounded, color: myColor,),
                          items: subjectsItems.map((String items) {
                            return DropdownMenuItem(
                              value: items,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.50,
                                child: Text(items, style: const TextStyle(color: myColor), maxLines: 1, overflow: TextOverflow.ellipsis,),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              dropDownValue = newValue!;
                            });
                          },
                        ),
                        Row(
                          children: [
                            GestureDetector(
                                onTap: deleteAllReports,
                                child: Tooltip(
                                    message: 'Delete all reports', child: Container(
                                    padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, right: 5.0,),
                                    child: const Icon(Icons.delete_outline, size: 25.0,),
                                )
                                )
                            ),
                            GestureDetector(
                              onTap: ()=> exportToExcel(filteredList,),
                              child: Tooltip(
                                  message: 'Export to excel', child: Container(
                                  padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 5.0,),
                                  child: const Icon(Icons.drive_folder_upload_outlined, size: 25.0,),
                                )
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 5.0,),
                    ToggleSwitch(
                      activeBgColor: MediaQuery.of(context).platformBrightness == Brightness.dark? [myColor] : [myLightColor!],
                      initialLabelIndex: toggleLabelIndex,
                      labels: const ['In', 'Out', 'Both'],
                      radiusStyle: true,
                      cornerRadius: 20.0,
                      inactiveBgColor: (MediaQuery.of(context).platformBrightness == Brightness.light)? Colors.grey[300] : Colors.grey[900],
                      totalSwitches: 3,
                      onToggle: (index) {
                        setState(() {
                          toggleLabelIndex = index!;
                        });
                      },
                    ),
                    const SizedBox(height: 10.0,),
                    TextField(
                      controller: searchNameTextController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.search),
                        label: Text('Search Student'),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10.0,),
                    TextField(
                      controller: searchGradeSectionTextController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        suffixIcon: Icon(Icons.search),
                        label: Text('Search Grade and Section'),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 15.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        dateTextContainer(fromDateController, 'From Date', true,),
                        dateTextContainer(toDateController, 'To Date', false,),
                      ],
                    ),
                    Visibility(
                      visible: filteredList.isNotEmpty,
                      child: Column(
                        children: [
                          const SizedBox(height: 20.0,),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Total Attendance Reports: ${filteredList.length}', style: const TextStyle(fontSize: 12.0),),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            (filteredList.isEmpty)? const SliverToBoxAdapter(child: Center(child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Text('No Student Report'),
            ),),) :
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: filteredList.length,
                    (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.5,),
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 1.0,),
                      child: widget.user.role == 'Guard'? guardListTile(filteredList[index]) : teacherListTile(filteredList[index]),
                    ),
                ),
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget teacherListTile(Student student) {
    return ListTile(
      title: Text('${student.name} | ${student.gender}', style: const TextStyle(fontWeight: FontWeight.w500),),
      // subtitle: Text('${student.gradeSection} - ${student.subject}'),
      subtitle: Text(student.subject),
      leading: CircleAvatar(
        backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.dark? myColor : myLightColor,
        child: Text((student.isIn)? 'In' : 'Out', style: const TextStyle(color: Colors.white),),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${student.date.hour.toString().padLeft(2, '0')}:${student.date.minute.toString().padLeft(2, '0')}'),
          Text('${student.date.day}/${student.date.month}/${student.date.year}'),
        ],
      ),
    );
  }

  Widget guardListTile(Student student) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: ListTile(
        title: Text('${student.name} | ${student.gender}', style: const TextStyle(fontWeight: FontWeight.w500),),
        // subtitle: Text(student.gradeSection),
        leading: CircleAvatar(
          backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.dark? myColor : myLightColor,
          child: Text((student.isIn)? 'In' : 'Out', style: const TextStyle(color: Colors.white),),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${student.date.hour.toString().padLeft(2, '0')}:${student.date.minute.toString().padLeft(2, '0')}'),
            Text('${student.date.day}/${student.date.month}/${student.date.year}'),
          ],
        ),
      ),
    );
  }

  void pickDate(TextEditingController textController, bool isFromDate) {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    ).then((value) {
      setState(() {
        isFromDate? (fromDate = value!) : (toDate = value!.add(const Duration(days: 1)));
        var date = '${value.day}/${value.month}/${value.year}';
        textController.text = date.toString();
      });
    });
  }

  Widget dateTextContainer(TextEditingController textController, String label, bool isFromDate) {
    return GestureDetector(
      onTap: () => pickDate(textController, isFromDate),
      child: SizedBox(
        width: 150,
        child: TextField(
          readOnly: true,
          enabled: false,
          controller: textController,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: MediaQuery.of(context).platformBrightness == Brightness.dark? Colors.white.withOpacity(0.3) : myColor),
            disabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: MediaQuery.of(context).platformBrightness == Brightness.dark? Colors.white.withOpacity(0.3) : myColor)
            ),
          ),
        ),
      ),
    );
  }
}
