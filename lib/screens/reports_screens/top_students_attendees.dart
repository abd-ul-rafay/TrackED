import 'dart:io';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../../utils/consts.dart';
import '../../models/Student.dart';
import '../../models/user.dart';
import 'package:mat_month_picker_dialog/mat_month_picker_dialog.dart';

class TopStudentsAttendeesScreen extends StatefulWidget {
  final User user;
  const TopStudentsAttendeesScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<TopStudentsAttendeesScreen> createState() => _TopStudentsAttendeesScreenState();
}

class _TopStudentsAttendeesScreenState extends State<TopStudentsAttendeesScreen> {
  final List<Student> _monthlyReport = [];
  Map<String, int> _studentsReport = {};

  final _dateController = TextEditingController(text: 'Select Month');
  final _noOfDaysController = TextEditingController(text: '30');
  DateTime? _selectedMonth = DateTime.now();

  final _items = [ // we will add teachers subject with it but first element will 'Select a Subject'
    'Select a Subject',
  ]; String _dropDownValue = 'Select a Subject';

  int getDaysOfMonth(DateTime? month) {
    // return DateTime(_selectedMonth?.year ?? DateTime.now().year, (_selectedMonth?.month ?? DateTime.now().year) + 1, 0).day;
    return DateTime((month ?? DateTime.now()).year, (month ?? DateTime.now()).month + 1, 0).day;
  }

  void getMonthlyReport() {
    // clearing all values, suppose orientation changed, values will increment, so clearing values
    _monthlyReport.clear();
    _studentsReport.clear();

    _dropDownValue = widget.user.role == 'Guard' ? '' : _dropDownValue;

    if (_dropDownValue == _items[0]) {
      return;
    }

    _selectedMonth ??= DateTime.now();

    // to get monthly report, we will iterate from first to last day of month and calculate result
    final firstDay = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1); // first date of that specific month
    final lastDay = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 1); // last date of that specific month

    for (DateTime date = firstDay; date.isBefore(lastDay); date = date.add(const Duration(days: 1))) {
      List<Student> thisDateReport = widget.user.studentsReport
          .where((student) => (student.date.day == date.day) && (student.date.month == date.month) && (student.date.year == date.year)
          && (student.subject == _dropDownValue) && student.isIn)
          .toList();

      // we have to now filter out (distinct) those student how are scanned multiply today using informational text
      List<Student> thisDateReportDistinct = thisDateReport.toSet().toList();

      _monthlyReport.addAll(thisDateReportDistinct);
    }

    for (var i in _monthlyReport) {
      if (_studentsReport.containsKey(i.name)) {
        _studentsReport[i.name] = (_studentsReport[i.name]! + 1);
      } else {
        _studentsReport[i.name] = 1;
      }
    }

    if (_studentsReport.isNotEmpty) {
      _studentsReport = Map.fromEntries(_studentsReport.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)));
    }
  }

  String getTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void exportToExcel() async {

    final currentSubjectIndex = _items.indexWhere((subject) => subject == _dropDownValue) - 1; // subtracting 1 because items contain 1 additional element
    final subjectSelected = (currentSubjectIndex != -1) && (_dropDownValue != _items[0]);

    if (!subjectSelected) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('Please select any subject first!'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    var allStudentsWithSubject = widget.user.studentsReport.where((element) => element.subject == _dropDownValue);
    var allStudentsThisMonth = allStudentsWithSubject.where((element) => element.date.month == (_selectedMonth ?? DateTime.now()).month && element.date.year == (_selectedMonth ?? DateTime.now()).year);


    if (_studentsReport.isEmpty) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('No report to export'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    // getting genders of students and relate it to Map
    Map<String, String> studentGenders = {};

    for (var student in allStudentsThisMonth) {
      if (!studentGenders.containsKey(student.name)) {
        studentGenders[student.name] = student.gender;
      }
    }

    var maleStudentsReport = Map.fromEntries(
        _studentsReport.entries.where((entry) =>
        studentGenders[entry.key] == 'M'
        )
    );

    var femaleStudentsReport = Map.fromEntries(
        _studentsReport.entries.where((entry) =>
        studentGenders[entry.key] == 'F'
        )
    );

    try {
      ex.Excel excel = ex.Excel.createExcel();
      ex.Sheet sheetObject = excel['Sheet1'];

      String selectedMonthFormat = DateFormat('MMM-yyyy').format(_selectedMonth ?? DateTime.now());

      var thinBorder = ex.Border(
        borderStyle: ex.BorderStyle.Thin,
        borderColorHex: '#000000',
      );

      var thinBorderStyle = ex.CellStyle(
        leftBorder: thinBorder,
        rightBorder: thinBorder,
        topBorder: thinBorder,
        bottomBorder: thinBorder,
      );

      ex.CellStyle titleStyle = ex.CellStyle(
        fontSize: 20, // Increase the font size
        bold: true, // Make the text bold
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
      );

      ex.CellStyle schoolTitleStyle = ex.CellStyle(
        bold: true, // Make the text bold
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
      );

      ex.CellStyle alignCenter = ex.CellStyle(
        horizontalAlign: ex.HorizontalAlign.Center,
        verticalAlign: ex.VerticalAlign.Center,
        bold: true,
      );

      var totalCellStyle = thinBorderStyle.copyWith(
          backgroundColorHexVal: '#fef2cd', // light yellow
      );

      var topBarCellStyle = thinBorderStyle.copyWith(
        backgroundColorHexVal: '#d1f1da', // light green
      );

      var attendanceCellStyle = thinBorderStyle.copyWith(
        backgroundColorHexVal: '#d9e7fd', // light blue
      );

      var totalAndCenterCellStyle = totalCellStyle.copyWith(
        horizontalAlignVal: ex.HorizontalAlign.Center,
        verticalAlignVal: ex.VerticalAlign.Center,
        boldVal: true,
      );

      sheetObject.merge(ex.CellIndex.indexByString("A1"), ex.CellIndex.indexByString("AQ1"));
      sheetObject.merge(ex.CellIndex.indexByString("A1"), ex.CellIndex.indexByString("A2"));
      sheetObject.cell(ex.CellIndex.indexByString("A1"))
        ..value = 'School Form 2 (SF2) Daily Attendance Report of Learners'
        ..cellStyle = titleStyle.copyWith(backgroundColorHexVal: '#bfbfbf');

      sheetObject.merge(ex.CellIndex.indexByString("A3"), ex.CellIndex.indexByString("AQ3"));
      sheetObject.cell(ex.CellIndex.indexByString("A3"))
        ..value = 'School ID: ${widget.user.schoolID} — School Name: ${widget.user.schoolName} — School Year: ${((_selectedMonth ?? DateTime.now()).year).toString()}'
        ..cellStyle = schoolTitleStyle;

      sheetObject.merge(ex.CellIndex.indexByString("A4"), ex.CellIndex.indexByString("AQ4"));
      sheetObject.cell(ex.CellIndex.indexByString("A4"))
        ..value = 'Subject: $_dropDownValue — Report for the month of: ${DateFormat.MMMM().format(_selectedMonth ?? DateTime.now())}'
        ..cellStyle = schoolTitleStyle;

      sheetObject.merge(ex.CellIndex.indexByString("A5"), ex.CellIndex.indexByString("AQ5"));

      sheetObject.merge(ex.CellIndex.indexByString("A6"), ex.CellIndex.indexByString("A7"));
      sheetObject.cell(ex.CellIndex.indexByString("A6"))
        ..value = 'No.'
        ..cellStyle = ex.CellStyle(
          bold: true,
        );

      sheetObject.setColWidth(0, 4);
      sheetObject.setColWidth(39, 3);

      sheetObject.merge(ex.CellIndex.indexByString("B6"), ex.CellIndex.indexByString("D6"));
      sheetObject.merge(ex.CellIndex.indexByString("B6"), ex.CellIndex.indexByString("B7"));
      sheetObject.cell(ex.CellIndex.indexByString("B6"))
        ..value = 'Name (Last Name, First Name, Middle Name)'
        ..cellStyle = ex.CellStyle(
          horizontalAlign: ex.HorizontalAlign.Center,
          verticalAlign: ex.VerticalAlign.Bottom,
          bold: true,
        );

      var weekDaysList = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      var shortWeekDaysList = ['M', 'T', 'W', 'TH', 'F', 'S', 'SU'];
      var dateColList = ['E6', 'F6', 'G6', 'H6', 'I6', 'J6', 'K6',
                     'L6', 'M6', 'N6', 'O6', 'P6', 'Q6', 'R6',
                     'S6', 'T6', 'U6', 'V6', 'W6', 'X6', 'Y6',
                     'Z6', 'AA6', 'AB6', 'AC6', 'AD6', 'AE6', 'AF6',
                     'AG6', 'AH6', 'AI6', 'AJ6', 'AK6', 'AL6', 'AM6',
                     'AN6', 'A06',];
      var weekColList = ['E7', 'F7', 'G7', 'H7', 'I7', 'J7', 'K7',
                     'L7', 'M7', 'N7', 'O7', 'P7', 'Q7', 'R7',
                     'S7', 'T7', 'U7', 'V7', 'W7', 'X7', 'Y7',
                     'Z7', 'AA7', 'AB7', 'AC7', 'AD7', 'AE7', 'AF7',
                     'AG7', 'AH7', 'AI7', 'AJ7', 'AK7', 'AL7', 'AM7',
                     'AN7', 'AO7', ];

      // setting border and color of remaining date and day columns
      var remainingCells = ['E6', 'F6', 'G6', 'H6', 'I6', 'J6', 'K6', 'L6', 'M6', 'AG6', 'AH6', 'AI6', 'AJ6', 'AK6', 'AL6', 'AM6', 'AN6', 'AO6',
                            'E7', 'F7', 'G7', 'H7', 'I7', 'J7', 'K7', 'L7', 'M7', 'AG7', 'AH7', 'AI7', 'AJ7', 'AK7', 'AL7', 'AM7', 'AN7', 'AO7'];

      for (int i = 0; i < remainingCells.length; i++) {
        sheetObject.cell(ex.CellIndex.indexByString(remainingCells[i]))
          ..value = ''
          ..cellStyle = topBarCellStyle;
      }

      var thisSelectedMonth = _selectedMonth ?? DateTime.now();
      var thisMonth = thisSelectedMonth.month;
      DateTime firstDayOfMonth = DateTime(thisSelectedMonth.year, thisMonth, 1);
      String startDayOfWeek = DateFormat('EEEE').format(firstDayOfMonth);
      int totalDaysInMonth = DateTime(thisSelectedMonth.year, thisSelectedMonth.month + 1, 0).day;

      var increment = 0;

      for (int i = 0; i < weekColList.length; i++) {

        if (i < 7) {
          if (weekDaysList[i] == startDayOfWeek && increment == 0) {
            increment += 1;
          }
        }
        if (increment != 0 && increment <= totalDaysInMonth) {
          sheetObject
              .cell(ex.CellIndex.indexByString(dateColList[i]))
              ..value = (increment).toString().padLeft(2, "0")
              ..cellStyle = topBarCellStyle.copyWith(
                horizontalAlignVal: ex.HorizontalAlign.Left,
              );

          var rowIndex = 7;
          for (var report in maleStudentsReport.keys) {

            var studentAbsent = allStudentsThisMonth.where((element) => element.name == report && element.date.day == increment).isEmpty;

            var valueToPut = 'x';

            var satSun = [5, 6, 12, 13, 19, 20, 26, 27, 33, 34];
            for (int j = 0; j < satSun.length; j++) {
              if (i == satSun[j]) {
                valueToPut = 'h';
                break;
              }
            }

            sheetObject
              .cell(ex.CellIndex.indexByColumnRow(rowIndex: rowIndex, columnIndex: i + 4,))
              ..value = studentAbsent ? valueToPut : ''
              ..cellStyle = attendanceCellStyle.copyWith(horizontalAlignVal: ex.HorizontalAlign.Center);

            rowIndex += 1;
          }

          rowIndex += 2;

          for (var report in femaleStudentsReport.keys) {

            var studentAbsent = allStudentsThisMonth.where((element) => element.name == report && element.date.day == increment).isEmpty;

            var valueToPut = 'x';

            var satSun = [5, 6, 12, 13, 19, 20, 26, 27, 33, 34];
            for (int j = 0; j < satSun.length; j++) {
              if (i == satSun[j]) {
                valueToPut = 'h';
                break;
              }
            }

            sheetObject
              .cell(ex.CellIndex.indexByColumnRow(rowIndex: rowIndex, columnIndex: i + 4,))
              ..value = studentAbsent ? valueToPut : ''
              ..cellStyle = attendanceCellStyle.copyWith(horizontalAlignVal: ex.HorizontalAlign.Center);

            rowIndex += 1;
          }

          increment++;
        }

        sheetObject.cell(ex.CellIndex.indexByString(weekColList[i]))
          ..value = shortWeekDaysList[i % 7]
          ..cellStyle = topBarCellStyle;

        sheetObject.setColAutoFit(i + 4);
      }

      int rowIndex = 7;

      sheetObject.setColAutoFit(39);
      sheetObject.setColAutoFit(40);

      var incrementalI = 1, totalMalePresent = 0, totalMaleAbsent = 0;
      for (var report in maleStudentsReport.keys) {
        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = '$incrementalI.'
          ..cellStyle = ex.CellStyle(horizontalAlign: ex.HorizontalAlign.Right);
        incrementalI++;

        sheetObject.merge(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = report;

        sheetObject.merge(ex.CellIndex.indexByString("AP6"), ex.CellIndex.indexByString("AQ6"));
        sheetObject.cell(ex.CellIndex.indexByString("AP6"))
          ..value = 'Total for the Month'
          ..cellStyle = ex.CellStyle(horizontalAlign: ex.HorizontalAlign.Center, bold: true);

        sheetObject.cell(ex.CellIndex.indexByString("AP7"))
          ..value = 'Present'
          ..cellStyle = alignCenter;
        sheetObject.cell(ex.CellIndex.indexByString("AQ7"))
          ..value = 'Absent'
          ..cellStyle = alignCenter;

        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 41, rowIndex: rowIndex))
          ..value = _studentsReport[report]
          ..cellStyle = totalCellStyle;
        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 42, rowIndex: rowIndex))
          ..value = (totalDaysInMonth - _studentsReport[report]!.toInt() ?? 0)
          ..cellStyle = totalCellStyle;

        totalMalePresent += _studentsReport[report]?.toInt() ?? 0;
        totalMaleAbsent += totalDaysInMonth - _studentsReport[report]!.toInt() ?? 0;

        rowIndex++;
      }

      // total for males
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 41, rowIndex: rowIndex))
        ..value = totalMalePresent
        ..cellStyle = totalCellStyle;
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 42, rowIndex: rowIndex))
        ..value = totalMaleAbsent
        ..cellStyle = totalCellStyle;

      // merging does columns which are in between males and females and adding text
      sheetObject.merge(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), ex.CellIndex.indexByColumnRow(columnIndex: 40, rowIndex: rowIndex));
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = 'Total for Males = '
        ..cellStyle = ex.CellStyle(horizontalAlign: ex.HorizontalAlign.Right);

      rowIndex += 1;
      sheetObject.merge(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));

      // resetting var for females
      incrementalI = 1;
      rowIndex += 1;
      var totalFemalePresent = 0, totalFemaleAbsent = 0;

      for (var report in femaleStudentsReport.keys) {
        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          ..value = '$incrementalI.'
          ..cellStyle = ex.CellStyle(horizontalAlign: ex.HorizontalAlign.Right);
        incrementalI++;

        sheetObject.merge(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = report;

        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 41, rowIndex: rowIndex))
          ..value = _studentsReport[report]
          ..cellStyle = totalCellStyle;
        sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 42, rowIndex: rowIndex))
          ..value = (totalDaysInMonth - _studentsReport[report]!.toInt() ?? 0)
          ..cellStyle = totalCellStyle;

        totalFemalePresent += _studentsReport[report]?.toInt() ?? 0;
        totalFemaleAbsent += totalDaysInMonth - _studentsReport[report]!.toInt() ?? 0;

        rowIndex++;
      }

      // total for females
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 41, rowIndex: rowIndex))
        ..value = totalFemalePresent
        ..cellStyle = totalCellStyle;

      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 42, rowIndex: rowIndex))
        ..value = totalFemaleAbsent
        ..cellStyle = totalCellStyle;

      // merging does columns which are in between males and females and adding text
      sheetObject.merge(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), ex.CellIndex.indexByColumnRow(columnIndex: 40, rowIndex: rowIndex));
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = 'Total for Females = '
        ..cellStyle = ex.CellStyle(horizontalAlign: ex.HorizontalAlign.Right);

      rowIndex += 1;
      sheetObject.merge(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), ex.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex));
      rowIndex += 1;
      sheetObject.merge(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), ex.CellIndex.indexByColumnRow(columnIndex: 40, rowIndex: rowIndex));
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = 'Combined Total = '
        ..cellStyle = ex.CellStyle(horizontalAlign: ex.HorizontalAlign.Right);

      // total for males and females
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 41, rowIndex: rowIndex))
        ..value = totalMalePresent + totalFemalePresent
        ..cellStyle = totalCellStyle;
      sheetObject.cell(ex.CellIndex.indexByColumnRow(columnIndex: 42, rowIndex: rowIndex))
        ..value = totalMaleAbsent + totalFemaleAbsent
        ..cellStyle = totalCellStyle;

      String timestamp = DateFormat('HH-mm-ss-dd-MM-yyyy').format(DateTime.now());

      var subjectInPlace = widget.user.role == 'Guard'? '' : '$_dropDownValue-';
      final String? path = await _getSavePath('Top-Attendees-$subjectInPlace$selectedMonthFormat-$timestamp');
      final excelData = excel.encode();
      if (path != null) {
        await File(path).writeAsBytes(excelData!).then((value) => {
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

  @override
  void initState() {
    _items.addAll(widget.user.subjects.map((subject) => subject.name).toList());
    _noOfDaysController.text = getDaysOfMonth(_selectedMonth).toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getMonthlyReport();
    int tableSrNoCount = 1;

    final currentSubjectIndex = _items.indexWhere((subject) => subject == _dropDownValue) - 1; // subtracting 1 because items contain 1 additional element
    final subjectSelected = (currentSubjectIndex != -1) && (_dropDownValue != _items[0]);

    var daysInMonth = getDaysOfMonth(_selectedMonth);

    try {
      daysInMonth = int.parse(_noOfDaysController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Students Attendees',),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 25.0,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                        visible: (widget.user.role != 'Guard'),
                        child: DropdownButton(
                        value: _dropDownValue,
                        icon: const Icon(Icons.arrow_downward_rounded, color: myColor,),
                        items: _items.map((String items) {
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
                            _monthlyReport.clear();
                            _dropDownValue = newValue!;

                            if (_dateController.text == 'Select Month') {
                              _dateController.text = '${DateTime.now().month}/${DateTime.now().year}';
                            }

                            if (widget.user.studentsReport.isEmpty) {
                              return;
                            }
                          });
                        },
                      ),
                      ),
                      GestureDetector(
                          onTap: ()=> exportToExcel(),
                          child: Tooltip(
                            message: 'Export to excel', child: Container(
                              padding: const EdgeInsets.only(top: 5.0, bottom: 5.0, left: 5.0,),
                              child: const Icon(Icons.drive_folder_upload_outlined),
                            )
                          )
                      ),
                    ],
                  ),
                  const SizedBox(height: 15.0,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      dateTextContainer(_dateController, 'Month',),
                      const SizedBox(width: 5.0,),
                      !subjectSelected
                      ? const SizedBox()
                      : SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.user.subjects[currentSubjectIndex].name, style: const TextStyle(fontSize: 16.0,), maxLines: 2, overflow: TextOverflow.ellipsis,),
                              Text('From ${getTime(widget.user.subjects[currentSubjectIndex].fromTime)} to ${getTime(widget.user.subjects[currentSubjectIndex].toTime)}',
                                style: const TextStyle(fontSize: 12.0,),
                              ),
                              Text('Males: ${widget.user.subjects[currentSubjectIndex].noOfMale} - Females: ${widget.user.subjects[currentSubjectIndex].noOfFemale}',
                                style: const TextStyle(fontSize: 12.0,),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15.0,),
            !subjectSelected
              ? const Center(child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Text('Select any subject', style: TextStyle(fontSize: 18.0,),),
            ),)
              : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Visibility(
                visible: _studentsReport.isNotEmpty,
                replacement: const Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Text('No report'),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${DateFormat('MMMM').format(_selectedMonth!)} Attendance Report'),
                    const SizedBox(height: 7.5,),
                    Row(
                      children: [
                        const Text('Number of Days: '),
                        const SizedBox(width: 5.0,),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            controller: _noOfDaysController,
                            onSubmitted: (value) {
                              try {
                                if (int.parse(value) > getDaysOfMonth(_selectedMonth) || int.parse(value) <= 0) {
                                  setState(() {
                                    _noOfDaysController.text =
                                        getDaysOfMonth(_selectedMonth).toString();
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()),),);
                              }
                            },
                            maxLength: 2,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(8),
                              counterText: '', // don't show digit at bottom corner
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0,),
                    Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      border: TableBorder.symmetric(inside: BorderSide(width: 1, color: isDarkTheme? Colors.white12 : Colors.blue.withOpacity(0.3)),),
                      columnWidths: {
                        0: FixedColumnWidth(MediaQuery.of(context).size.width * 0.10),
                        1: FixedColumnWidth(MediaQuery.of(context).size.width * 0.45),
                        2: FixedColumnWidth(MediaQuery.of(context).size.width * 0.175),
                        3: FixedColumnWidth(MediaQuery.of(context).size.width * 0.175),
                      },
                      children: [
                        TableRow(
                            children: [
                              Container(
                                  height: 40.0,
                                  color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                  child: const Center(
                                    child: Text('NO.',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.0,),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                              ),
                              Container(
                                  height: 40.0,
                                  color: isDarkTheme ? tableColorForDark : tableColor,
                                  padding: const EdgeInsets.only(left: 10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text('Student Name',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0,),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  )
                              ),
                              Container(
                                  height: 40.0,
                                  color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                  child: const Center(
                                    child: Text('Total \nAttendees',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.0,),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                              ),
                              Container(
                                  height: 40.0,
                                  color: isDarkTheme ? tableColorForDark : tableColor,
                                  child: const Center(
                                    child: Text('Total \nAbsentees',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.0,),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                              ),
                            ]
                        ),

                        for (var i in _studentsReport.keys)
                          TableRow(
                              children: [
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text('${tableSrNoCount++}.', style: const TextStyle(fontSize: 12.0), textAlign: TextAlign.center,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(i, style: const TextStyle(fontSize: 12.0), maxLines: 1, overflow: TextOverflow.ellipsis,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorLightForDark : tableColorLight,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text('${_studentsReport[i]}', overflow: TextOverflow.ellipsis, maxLines: 1, style: const TextStyle(fontSize: 12.0,), textAlign: TextAlign.center,)
                                ),
                                Container(
                                    color: isDarkTheme ? tableColorForDark : tableColor,
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text('${daysInMonth - _studentsReport[i]!}', style: const TextStyle(fontSize: 12.0), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.center,)
                                ),
                              ]
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pickDate(TextEditingController textController) async {

    await showMonthPicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1970),
        lastDate: DateTime(2050)
    ).then((value) {
      setState(() {

        String date;
        if (value != null) {
          date = '${value.month}/${value.year}';
        } else {
          date = '${DateTime.now().month}/${DateTime.now().year}';
        }

        textController.text = date.toString();

        _selectedMonth = value;
        _noOfDaysController.text = getDaysOfMonth(_selectedMonth).toString();
        _monthlyReport.clear();
      });
      return null;
    });

  }

  Widget dateTextContainer(TextEditingController textController, String label) {
    return GestureDetector(
      onTap: () => _dropDownValue == _items[0]? null : pickDate(textController),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: TextField(
          readOnly: true,
          enabled: false,
          controller: textController,
          style: const TextStyle(fontSize: 14.0),
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
