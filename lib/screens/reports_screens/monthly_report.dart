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
import 'package:mat_month_picker_dialog/mat_month_picker_dialog.dart';
import 'package:pie_chart/pie_chart.dart';

class MonthlyReportScreen extends StatefulWidget {
  final User user;
  const MonthlyReportScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final List<Student> _monthlyReport = [];
  final List<DailyReport> _dailyReport = [];

  final _dateController = TextEditingController(text: 'Select Month');
  final _noOfDaysController = TextEditingController(text: '30');
  DateTime? _selectedMonth = DateTime.now();

  final _items = [ // we will add teachers subject with it but first element will 'Select a Subject'
    'Select a Subject',
  ]; String _dropDownValue = 'Select a Subject';

  int _attendeesMale = 0, _attendeesFemale = 0, _absenteesMale = 0, _absenteesFemale = 0;
  double _percentageMaleAttendees = 0.0, _percentageFemaleAttendees = 0.0, _percentageMaleAbsentees = 0.0, _percentageFemaleAbsentees = 0.0;

  int getDaysOfMonth(DateTime? month) {
    return DateTime(_selectedMonth?.year ?? DateTime.now().year, (_selectedMonth?.month ?? DateTime.now().year) + 1, 0).day;
  }

  void getMonthlyReport() {
    // clearing all values, suppose orientation changed, values will increment, so clearing values
    _monthlyReport.clear();
    _dailyReport.clear();
    _attendeesMale = 0; _attendeesFemale = 0; _absenteesMale = 0; _absenteesFemale = 0;
    _percentageMaleAttendees = 0.0; _percentageFemaleAttendees = 0.0; _percentageMaleAbsentees = 0.0; _percentageFemaleAbsentees = 0.0;

    if (_dropDownValue == _items[0] && widget.user.role != 'Guard') {
      return;
    }

    _selectedMonth ??= DateTime.now();

    var currentSubject = widget.user.subjects.where((subject) => subject.name == ((widget.user.role == 'Guard')? '' : _dropDownValue)).toList().first;

    // to get monthly report, we will iterate from first to last day of month and calculate result
    final firstDay = DateTime(_selectedMonth!.year, _selectedMonth!.month, 1); // first date of that specific month
    var lastDay = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1, 1); // last date of that specific month

    if (widget.user.role == 'Guard') {
      _dropDownValue = '';
    }

    for (DateTime date = firstDay; date.isBefore(lastDay); date = date.add(const Duration(days: 1))) {
      List<Student> thisDateReport = widget.user.studentsReport
          .where((student) => (student.date.day == date.day) && (student.date.month == date.month) && (student.date.year == date.year)
          && (student.subject == _dropDownValue) && student.isIn)
          .toList();

      // we have to now filter out (distinct) those student how are scanned multiply using informational text
      List<Student> thisDateReportDistinct = thisDateReport.toSet().toList();

      _monthlyReport.addAll(thisDateReportDistinct);

      // this is for exporting to excel
      var attendeesMaleDaily = thisDateReportDistinct.where((student) => student.gender == 'M').length;
      var attendeesFemaleDaily = thisDateReportDistinct.where((student) => student.gender == 'F').length;
      var absenteesMaleDaily = int.parse(currentSubject.noOfMale) - attendeesMaleDaily; // total - present
      var absenteesFemaleDaily = int.parse(currentSubject.noOfFemale) - attendeesFemaleDaily; // total - present
      var combinedAttendeesDaily = attendeesMaleDaily + attendeesFemaleDaily;
      var combinedAbsenteesDaily = absenteesMaleDaily + absenteesFemaleDaily;

      // if there is no attendance on specific day, show - instead of 0
      var isAnyAttendance = (attendeesMaleDaily > 0 || attendeesFemaleDaily > 0);

      _dailyReport.add(DailyReport(
          date: date,
          attendeesMale: !isAnyAttendance? '-' : attendeesMaleDaily.toString(),
          attendeesFemale: !isAnyAttendance? '-' : attendeesFemaleDaily.toString(),
          absenteesMale: !isAnyAttendance? '-' : absenteesMaleDaily.toString(),
          absenteesFemale: !isAnyAttendance? '-' : absenteesFemaleDaily.toString(),
          combinedAttendees: !isAnyAttendance? '-' : combinedAttendeesDaily.toString(),
          combinedAbsentees: !isAnyAttendance? '-' : combinedAbsenteesDaily.toString()));
    }

    for (var i in _monthlyReport) {
      if (i.gender == 'M') {
        _attendeesMale += 1;
      } else if (i.gender == 'F') {
        _attendeesFemale += 1;
      }
    }

    var totalDays = DateTime.now().day;

    try {
      totalDays = int.parse(_noOfDaysController.text);
      lastDay = DateTime(_selectedMonth!.year, _selectedMonth!.month, totalDays + 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    _absenteesMale = (int.parse(currentSubject.noOfMale) * totalDays) - _attendeesMale;
    _absenteesFemale = (int.parse(currentSubject.noOfFemale) * totalDays) - _attendeesFemale;

    if (int.parse(currentSubject.noOfMale) > 0) {
      _percentageMaleAttendees = (_attendeesMale / (int.parse(currentSubject.noOfMale) * totalDays)) * 100;
      _percentageMaleAbsentees = 100 - _percentageMaleAttendees;
    }

    if (int.parse(currentSubject.noOfFemale) > 0) {
      _percentageFemaleAttendees = (_attendeesFemale / (int.parse(currentSubject.noOfFemale) * totalDays)) * 100;
      _percentageFemaleAbsentees = 100 - _percentageFemaleAttendees;
    }

  }

  String getTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void exportToExcel() async {

    final currentSubjectIndex = _items.indexWhere((subject) => subject == _dropDownValue) - 1; // subtracting 1 because items contain 1 additional element
    var subjectSelected = (currentSubjectIndex != -1) && (_dropDownValue != _items[0]);

    if (widget.user.role == 'Guard') {
      subjectSelected = true;
    }

    if (!subjectSelected) {
      showDialog(context: context, builder: (context) => AlertDialog(
        content: const Text('Please select any subject first!'),
        actions: [TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Ok'))],
      ),);

      return;
    }

    try {
      Excel excel = Excel.createExcel();
      Sheet sheetObject = excel['Sheet1'];

      String selectedMonthFormat = DateFormat('MMM-yyyy').format(_selectedMonth ?? DateTime.now());

      // subject, month, days, males in subject, females in subject, total males, total females, attendees males, attendees females, absentees males, absentees females, combined students, attendees students, absentees students

      sheetObject.cell(CellIndex.indexByString("A1")).value = 'Category';
      sheetObject.cell(CellIndex.indexByString("B1")).value = 'Count';

      sheetObject.setColWidth(0, 25);

      int rowIndex = 2;

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? 'School Name' : 'Subject';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? widget.user.schoolName : widget.user.subjects[currentSubjectIndex].name;
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Month';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = DateFormat('MMMM').format(_selectedMonth ?? DateTime.now());
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Days';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = int.parse(_noOfDaysController.text);
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? 'Males in School' : 'Males in Subject';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? int.parse(widget.user.subjects[0].noOfMale) : int.parse(widget.user.subjects[currentSubjectIndex].noOfMale);
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? 'Females in School' : 'Females in Subject';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? int.parse(widget.user.subjects[0].noOfFemale) : int.parse(widget.user.subjects[currentSubjectIndex].noOfFemale);
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Total Males';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? int.parse(widget.user.subjects[0].noOfMale) * int.parse(_noOfDaysController.text) : int.parse(widget.user.subjects[currentSubjectIndex].noOfMale) * int.parse(_noOfDaysController.text);
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Total Females';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = (widget.user.role == 'Guard')? int.parse(widget.user.subjects[0].noOfFemale) * int.parse(_noOfDaysController.text) : int.parse(widget.user.subjects[currentSubjectIndex].noOfFemale) * int.parse(_noOfDaysController.text);
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Attendees Males';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = _attendeesMale;
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Absentees Males';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = _absenteesMale;
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Attendees Females';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = _attendeesFemale;
      rowIndex += 1;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = 'Absentees Females';
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = _absenteesFemale;
      rowIndex += 1;

      String timestamp = DateFormat('HH-mm-ss-dd-MM-yyyy').format(DateTime.now());

      final String? path = await _getSavePath('Monthly-Report-$_dropDownValue-$selectedMonthFormat-$timestamp');
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getMonthlyReport();

    var currentSubjectIndex = _items.indexWhere((subject) => subject == _dropDownValue) - 1; // subtracting 1 because items contain 1 additional element
    var subjectSelected = (currentSubjectIndex != -1) && (_dropDownValue != _items[0]);

    if (widget.user.role == 'Guard') {
      subjectSelected = true;
      currentSubjectIndex = 0;
    }

    var daysInMonth = 0;
    try {
      if (_noOfDaysController.text.isNotEmpty) {
        daysInMonth = int.parse(_noOfDaysController.text);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    var chartValuesUndefined = false;

    // they will become NaN if there is no student
    if (_percentageMaleAttendees.isNaN || _percentageMaleAbsentees.isNaN || _percentageFemaleAttendees.isNaN || _percentageFemaleAbsentees.isNaN) {
      _percentageMaleAttendees = _percentageMaleAbsentees = _percentageFemaleAttendees = _percentageFemaleAbsentees = 0.0;
      chartValuesUndefined = true;
    }

    final Map<String, double> maleFemaleDataMap = {
      'Attendees Male    ': _percentageMaleAttendees,
      'Absentees Male': _percentageMaleAbsentees,
      'Attendees Female': _percentageFemaleAttendees,
      'Absentees Female': _percentageFemaleAbsentees,
    };

    final Map<String, double> maleDataMap = {
      'Attendees Male    ': _percentageMaleAttendees,
      'Absentees Male': _percentageMaleAbsentees,
    };

    final Map<String, double> femaleDataMap = {
      'Attendees Female': _percentageFemaleAttendees,
      'Absentees Female': _percentageFemaleAbsentees,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Report',),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Visibility(
              visible: (widget.user.role != 'Guard'),
              child: const SizedBox(height: 25.0,)
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Visibility(
                        visible: widget.user.role != 'Guard',
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

                              _noOfDaysController.text = getDaysOfMonth(_selectedMonth).toString();

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
                              Text((widget.user.role == 'Guard')? widget.user.schoolName : widget.user.subjects[currentSubjectIndex].name, style: const TextStyle(fontSize: 16.0,), maxLines: 2, overflow: TextOverflow.ellipsis,),
                              Visibility(
                                visible: (widget.user.role != 'Guard'),
                                child: Text('From ${getTime(widget.user.subjects[currentSubjectIndex].fromTime)} to ${getTime(widget.user.subjects[currentSubjectIndex].toTime)}',
                                  style: const TextStyle(fontSize: 12.0,),
                                ),
                              ),
                              Text('Males: ${widget.user.subjects[currentSubjectIndex].noOfMale} - Females: ${widget.user.subjects[currentSubjectIndex].noOfFemale}',
                                style: const TextStyle(fontSize: 12.0,),
                              ),
                              Visibility(
                                visible: (widget.user.role == 'Guard'),
                                child: Text('Number of Students: ${int.parse(widget.user.subjects[currentSubjectIndex].noOfMale) + int.parse(widget.user.subjects[currentSubjectIndex].noOfFemale)}',
                                  style: const TextStyle(fontSize: 12.0,),
                                ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${DateFormat('MMMM').format(_selectedMonth ?? DateTime.now())} Attendance Report'),
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
                  const SizedBox(height: 5.0,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Males: \n${widget.user.subjects[currentSubjectIndex].noOfMale} × $daysInMonth = '
                          '${int.parse(widget.user.subjects[currentSubjectIndex].noOfMale) * daysInMonth}',
                        style: const TextStyle(fontSize: 12.0,),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Attendees Male: $_attendeesMale', style: const TextStyle(fontSize: 12.0,),),
                          Text('Absentees Male: $_absenteesMale', style: const TextStyle(fontSize: 12.0,),),
                        ],
                      )
                    ],
                  ),
                  const Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Females: \n${widget.user.subjects[currentSubjectIndex].noOfFemale} × $daysInMonth = '
                            '${int.parse(widget.user.subjects[currentSubjectIndex].noOfFemale) * daysInMonth}',
                          style: const TextStyle(fontSize: 12.0,),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Attendees Female: $_attendeesFemale', style: const TextStyle(fontSize: 12.0,),),
                            Text('Absentees Female: $_absenteesFemale', style: const TextStyle(fontSize: 12.0,),),
                          ],
                        )
                      ],
                    ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Combined Students: \n${int.parse(widget.user.subjects[currentSubjectIndex].noOfFemale) + int.parse(widget.user.subjects[currentSubjectIndex].noOfMale)} × $daysInMonth = '
                          '${(int.parse(widget.user.subjects[currentSubjectIndex].noOfFemale) + int.parse(widget.user.subjects[currentSubjectIndex].noOfMale)) * daysInMonth}',
                        style: const TextStyle(fontSize: 12.0,),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Attendees Students: ${_attendeesMale + _attendeesFemale}', style: const TextStyle(fontSize: 12.0,),),
                          Text('Absentees Students: ${_absenteesMale + _absenteesFemale}', style: const TextStyle(fontSize: 12.0,),),
                        ],
                      )
                    ],
                  ),
                  const Divider(),
                  Visibility(
                    visible: !chartValuesUndefined,
                    replacement: const Padding(
                      padding: EdgeInsets.only(top: 20.0),
                      child: Center(
                        child: Text('The chart cannot be displayed because there are possibly no students or the number of students is zero',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20.0,),
                        const Text('Combined Students Chart:'),
                        const SizedBox(height: 20.0,),
                        PieChart(
                          dataMap: maleFemaleDataMap,
                          chartRadius: MediaQuery.of(context).orientation == Orientation.portrait
                              ? MediaQuery.of(context).size.width * 0.65
                              : MediaQuery.of(context).size.width * 0.40,
                          colorList: MediaQuery.of(context).platformBrightness == Brightness.dark
                              ? [
                            Colors.red[800]!.withOpacity(0.8),
                            Colors.blue[800]!.withOpacity(0.8),
                            Colors.yellow[800]!.withOpacity(0.8),
                            Colors.green[800]!.withOpacity(0.8),
                          ]
                              : const [
                            Color(0xFFff7675),
                            Color(0xFF74b9ff),
                            Color(0xFFffeaa7),
                            Color(0xFF55efc4),
                          ],
                          legendOptions: const LegendOptions(
                            legendPosition: LegendPosition.bottom,
                            showLegendsInRow: true,
                            legendTextStyle: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValueBackground: false,
                            chartValueStyle: TextStyle(
                              fontSize: 15.0,
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.grey,
                            ),
                            showChartValues: true,
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: true,
                            decimalPlaces: 1,
                          ),
                        ),
                        const SizedBox(height: 10.0,),
                        const Text('Male Students Chart:'),
                        const SizedBox(height: 20.0,),
                        PieChart(
                          dataMap: maleDataMap,
                          chartRadius: MediaQuery.of(context).orientation == Orientation.portrait
                              ? MediaQuery.of(context).size.width * 0.65
                              : MediaQuery.of(context).size.width * 0.40,
                          colorList: MediaQuery.of(context).platformBrightness == Brightness.dark
                              ? [
                            Colors.red[800]!.withOpacity(0.8),
                            Colors.blue[800]!.withOpacity(0.8),
                          ]
                              : const [
                            Color(0xFFff7675),
                            Color(0xFF74b9ff),
                          ],
                          legendOptions: const LegendOptions(
                            legendPosition: LegendPosition.bottom,
                            showLegendsInRow: false,
                            legendTextStyle: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValueBackground: false,
                            chartValueStyle: TextStyle(
                              fontSize: 15.0,
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.grey,
                            ),
                            showChartValues: true,
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: true,
                            decimalPlaces: 1,
                          ),
                        ),
                        const SizedBox(height: 10.0,),
                        const Text('Female Students Chart:'),
                        const SizedBox(height: 20.0,),
                        PieChart(
                          dataMap: femaleDataMap,
                          chartRadius: MediaQuery.of(context).orientation == Orientation.portrait
                              ? MediaQuery.of(context).size.width * 0.65
                              : MediaQuery.of(context).size.width * 0.40,
                          colorList: MediaQuery.of(context).platformBrightness == Brightness.dark
                              ? [
                            Colors.yellow[800]!.withOpacity(0.8),
                            Colors.green[800]!.withOpacity(0.8),
                          ]
                              : const [
                            Color(0xFFffeaa7),
                            Color(0xFF55efc4),
                          ],
                          legendOptions: const LegendOptions(
                            legendPosition: LegendPosition.bottom,
                            showLegendsInRow: false,
                            legendTextStyle: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValueBackground: false,
                            chartValueStyle: TextStyle(
                              fontSize: 15.0,
                              color: MediaQuery.of(context).platformBrightness == Brightness.light ? Colors.black : Colors.grey,
                            ),
                            showChartValues: true,
                            showChartValuesInPercentage: true,
                            showChartValuesOutside: true,
                            decimalPlaces: 1,
                          ),
                        ),
                      ],
                    ),
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
        _monthlyReport.clear();
      });
      return null;
    });

  }

  Widget dateTextContainer(TextEditingController textController, String label) {
    return GestureDetector(
      onTap: () => (_dropDownValue != _items[0] || widget.user.role == 'Guard')? pickDate(textController) : null,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.35,
        child: TextField(
          readOnly: true,
          enabled: false,
          style: const TextStyle(fontSize: 14.0),
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
