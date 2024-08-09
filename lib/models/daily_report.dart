
class DailyReport {
  final DateTime date;
  final String attendeesMale;
  final String attendeesFemale;
  final String absenteesMale;
  final String absenteesFemale;
  final String combinedAttendees;
  final String combinedAbsentees;

  DailyReport({
      required this.date,
      required this.attendeesMale,
      required this.attendeesFemale,
      required this.absenteesMale,
      required this.absenteesFemale,
      required this.combinedAttendees,
      required this.combinedAbsentees});
}
