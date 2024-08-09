import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../../utils/consts.dart';
import '../../models/Student.dart';
import '../../models/daily_report.dart';
import '../../models/user.dart';

class DailyReportScreen extends StatefulWidget {
  final User user;
  const DailyReportScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final List<DailyReport> _dailyReport = [];
  DateTime? _lowestDate;
  DateTime? _highestDate;

  final _fromDateController = TextEditingController(text: 'Select Date');
  final _toDateController = TextEditingController(text: 'Select Date');

  late DateTime fromDate, toDate;
  bool _isFromDate = true;
  bool _isDatePicked = false;

  var items = [ // we will add teachers subject with it but first element will 'Select a Subject'
    'Select a Subject',
  ]; String dropDownValue = 'Select a Subject';

  DateTime getLowestDate() {
    final filteredList = widget.user.studentsReport
        .where((student) => student.subject == dropDownValue);

    if (filteredList.isEmpty) {
      return DateTime.now().subtract(const Duration(days: 365 * 2)); // 2 years
    }

    return filteredList
        .map((student) => student.date)
        .reduce((value, element) => value.isBefore(element) ? value : element);
  }

  DateTime getHighestDate() {
    final filteredList = widget.user.studentsReport
        .where((student) => student.subject == dropDownValue);

    if (filteredList.isEmpty) {
      return DateTime.now().add(const Duration(days: 365 * 2)); // 2 years
    }

    return filteredList
        .map((student) => student.date)
        .reduce((value, element) => value.isAfter(element) ? value : element).add(const Duration(days: 1));
  }

  void getDailyReport() {
    final filteredList = widget.user.studentsReport
        .where((student) => student.subject == dropDownValue);

    if (widget.user.role == 'Guard') {
      dropDownValue = '';
    }

    if (filteredList.isEmpty) {
      _lowestDate = null;
      _highestDate = null;

      fromDate = DateTime.now();
      toDate = DateTime.now();
      return;
    }

    _dailyReport.clear();

    // if user pick some date, then set lowest and highest to what user picked
    if (!_isDatePicked) {
      _lowestDate = getLowestDate();
      _highestDate = getHighestDate();

      if (_lowestDate?.day == _highestDate?.day && _lowestDate?.month == _highestDate?.month && _lowestDate?.year == _highestDate?.year) {
        _highestDate = _highestDate?.add(const Duration(days: 1)); // adding highestDate one day to avoid conflict
      }

      fromDate = _lowestDate!;
      toDate = _highestDate!;
    } else {
      _lowestDate = fromDate;

      if (_isFromDate) {
        _highestDate = toDate;
      } else {
        _highestDate = toDate;
      }
    }

    var currentSubject = widget.user.subjects.where((subject) => subject.name == dropDownValue).toList().first;
    
    for (DateTime date = _lowestDate!; date.isBefore(_highestDate!); date = date.add(const Duration(days: 1))) {
      List<Student> thisDateReport = widget.user.studentsReport
          .where((student) => (student.date.day == date.day) && (student.date.month == date.month) && (student.date.year == date.year)
            && (student.subject == dropDownValue) && (!student.date.isBefore(fromDate)
            && !student.date.isAfter(toDate)) && student.isIn)
            .toList();

      // we have to now filter out (distinct) those student how are scanned multiply using informational text
      List<Student> todayReportDistinct = thisDateReport.toSet().toList();

      var attendeesMale = todayReportDistinct.where((student) => student.gender == 'M').length;
      var attendeesFemale = todayReportDistinct.where((student) => student.gender == 'F').length;
      var absenteesMale = int.parse(currentSubject.noOfMale) - attendeesMale; // total - present
      var absenteesFemale = int.parse(currentSubject.noOfFemale) - attendeesFemale; // total - present
      var combinedAttendees = attendeesMale + attendeesFemale;
      var combinedAbsentees = absenteesMale + absenteesFemale;

      // if there is no attendance on specific day, show - instead of 0
      var isAnyAttendance = (attendeesMale > 0 || attendeesFemale > 0);

      _dailyReport.add(DailyReport(
          date: date,
          attendeesMale: !isAnyAttendance? '-' : attendeesMale.toString(),
          attendeesFemale: !isAnyAttendance? '-' : attendeesFemale.toString(),
          absenteesMale: !isAnyAttendance? '-' : absenteesMale.toString(),
          absenteesFemale: !isAnyAttendance? '-' : absenteesFemale.toString(),
          combinedAttendees: !isAnyAttendance? '-' : combinedAttendees.toString(),
          combinedAbsentees: !isAnyAttendance? '-' : combinedAbsentees.toString()));
    }
  }

  void exportToExcel(List<DailyReport> dailyReport,) async {

    if (dailyReport.isEmpty) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('No student report to export!'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    try {
      Excel excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      sheetObject.cell(CellIndex.indexByString("A1")).value = 'Date';
      sheetObject.cell(CellIndex.indexByString("B1")).value = 'Attendees Male';
      sheetObject.cell(CellIndex.indexByString("C1")).value = 'Attendees Female';
      sheetObject.cell(CellIndex.indexByString("D1")).value = 'Absentees Male';
      sheetObject.cell(CellIndex.indexByString("E1")).value = 'Absentees Female';
      sheetObject.cell(CellIndex.indexByString("F1")).value = 'Combined Attendees';
      sheetObject.cell(CellIndex.indexByString("G1")).value = 'Combined Absentees';

      int rowIndex = 2;

      for (DailyReport report in dailyReport) {
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = '${report.date.day}/${report.date.month}/${report.date.year}';
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = report.attendeesMale;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = report.attendeesFemale;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = report.absenteesMale;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = report.absenteesFemale;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = report.combinedAttendees;
        sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = report.combinedAbsentees;

        rowIndex++;
      }

      String timestamp = DateFormat('HH-mm-ss-dd-MM-yyyy').format(DateTime.now());

      final String? path = await _getSavePath('Daily-Report-$dropDownValue-$timestamp');
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

  @override
  void initState() {
    items.addAll(widget.user.subjects.map((subject) => subject.name).toList());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getDailyReport();
    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Report',),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: (widget.user.role != 'Guard'),
              child: const SizedBox(height: 25.0,),
            ),
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
                          value: dropDownValue,
                          icon: const Icon(Icons.arrow_downward_rounded, color: myColor,),
                          items: items.map((String items) {
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
                              _dailyReport.clear();
                              dropDownValue = newValue!;

                              _fromDateController.text = 'Select Date';
                              _toDateController.text = 'Select Date';

                              if (widget.user.studentsReport.isEmpty) {
                                return;
                              }

                              _lowestDate = fromDate = getLowestDate();
                              _highestDate = toDate = getHighestDate();

                              if (_lowestDate?.day == _highestDate?.day && _lowestDate?.month == _highestDate?.month && _lowestDate?.year == _highestDate?.year) {
                                _highestDate = toDate = getHighestDate().add(const Duration(days: 1)); // adding highestDate one day to avoid conflict
                              }
                            });
                          },
                        ),
                      ),
                      GestureDetector(
                          onTap: ()=> exportToExcel(_dailyReport,),
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
                      dateTextContainer(_fromDateController, 'From Date', true,),
                      dateTextContainer(_toDateController, 'To Date', false,),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15.0,),
            dropDownValue == items[0]
            ? const Center(child: Padding(
              padding: EdgeInsets.only(top: 50.0),
              child: Text('Select any subject', style: TextStyle(fontSize: 18.0,),),
            ),)
            : (_lowestDate == null || _highestDate == null)
            ? const Center(child: Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: Text('No Report', style: TextStyle(fontSize: 18.0,),)
            ),)
            : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder.symmetric(inside: BorderSide(width: 1, color: isDarkTheme? Colors.white12 : Colors.blue.withOpacity(0.3)),),
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: IntrinsicColumnWidth(),
                  3: IntrinsicColumnWidth(),
                  4: IntrinsicColumnWidth(),
                  5: IntrinsicColumnWidth(),
                  6: IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(
                    children: [
                      Container(
                          padding: const EdgeInsets.all(5.0),
                        color: isDarkTheme? tableColorLightForDark : tableColorLight,
                        child: const Text(
                        '\nDate',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                          padding: const EdgeInsets.all(5.0),
                          color: isDarkTheme? tableColorForDark : tableColor,
                          child: const Text('Attendees\nM',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.all(5.0),
                          color: isDarkTheme? tableColorLightForDark : tableColorLight,
                          child: const Text('Attendees\nF',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.all(5.0),
                          color: isDarkTheme? tableColorForDark : tableColor,
                          child: const Text('Absentees\nM',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.all(5.0),
                          color: isDarkTheme? tableColorLightForDark : tableColorLight,
                          child: const Text('Absentees\nF',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.all(5.0),
                          color: isDarkTheme? tableColorForDark : tableColor,
                          child: const Text('Combined\nAttendees',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          )
                      ),
                      Container(
                          padding: const EdgeInsets.all(5.0),
                          color: isDarkTheme? tableColorLightForDark : tableColorLight,
                            child: const Text('Combined\nAbsentees',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10.0),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            )
                        ),
                    ]
                  ),

                  // We want to go from first date to last date to create table
                  for (var report in _dailyReport)
                    TableRow(
                      children: [
                        Container(
                            padding: const EdgeInsets.all(5.0),
                            color: isDarkTheme? tableColorLightForDark : tableColorLight,
                            child: Text('${report.date.day}/${report.date.month}/${report.date.year}', style: const TextStyle(fontSize: 10.0), textAlign: TextAlign.center,  overflow: TextOverflow.ellipsis,)
                        ),
                        Container(
                            padding: const EdgeInsets.all(5.0),
                            color: isDarkTheme? tableColorForDark : tableColor,
                            child: Text(report.attendeesMale, style: const TextStyle(fontSize: 10.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                        ),
                        Container(
                            padding: const EdgeInsets.all(5.0),
                            color: isDarkTheme? tableColorLightForDark : tableColorLight,
                            child: Text(report.attendeesFemale, style: const TextStyle(fontSize: 10.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                        ),
                        Container(
                            padding: const EdgeInsets.all(5.0),
                            color: isDarkTheme? tableColorForDark : tableColor,
                            child: Text(report.absenteesMale, style: const TextStyle(fontSize: 10.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                        ),
                        Container(
                            padding: const EdgeInsets.all(5.0),
                            color: isDarkTheme? tableColorLightForDark : tableColorLight,
                            child: Text(report.absenteesFemale, style: const TextStyle(fontSize: 10.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                        ),
                        Container(
                            padding: const EdgeInsets.all(5.0),
                            color: isDarkTheme? tableColorForDark : tableColor,
                            child: Text(report.combinedAttendees, style: const TextStyle(fontSize: 10.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                        ),
                        Container(
                            padding: const EdgeInsets.all(5.0),
                            color: isDarkTheme? tableColorLightForDark : tableColorLight,
                            child: Text(report.combinedAbsentees, style: const TextStyle(fontSize: 10.0), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,)
                        ),
                      ]
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15.0,),
          ],
        ),
      ),
    );
  }

  void pickDate(TextEditingController textController, bool isFromDate) {
    showDatePicker(
      context: context,
      initialDate: getLowestDate(),
      firstDate: getLowestDate(),
      lastDate: getHighestDate(),
    ).then((value) {
      value ??= DateTime.now();

      setState(() {
        isFromDate? (fromDate = value!) : (toDate = value!.add(const Duration(days: 1)));
        var date = '${value.day}/${value.month}/${value.year}';
        textController.text = date.toString();

        _isDatePicked = true;

        if (isFromDate) {
          _lowestDate = fromDate;
        } else {
          _highestDate = toDate;
        }

        _isFromDate = isFromDate;
        _dailyReport.clear();
      });
    });
  }

  Widget dateTextContainer(TextEditingController textController, String label, bool isFromDate) {
    return GestureDetector(
      onTap: () => dropDownValue == items[0]? null : pickDate(textController, isFromDate),
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
