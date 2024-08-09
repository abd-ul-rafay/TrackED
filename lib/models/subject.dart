
class Subject {
  String name;
  String noOfMale;
  String noOfFemale;
  DateTime fromTime;
  DateTime toTime;

  Subject({required this.name, required this.noOfMale, required this.noOfFemale, required this.fromTime, required this.toTime});

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'noOfMale': noOfMale,
      'noOfFemale': noOfFemale,
      'fromTime': fromTime.toIso8601String(),
      'toTime': toTime.toIso8601String(),
    };
  }

  static Subject fromJson(Map<String, dynamic> json) {
    return Subject(
      name: json['name'] ?? '',
      noOfMale: json['noOfMale'] ?? '',
      noOfFemale: json['noOfFemale'] ?? '',
      fromTime: DateTime.parse(json['fromTime']),
      toTime: DateTime.parse(json['toTime']),
    );
  }
}
