class ReportModel {
  final int studentsCount;
  final int teachersCount;
  final int parentsCount;
  final int classesCount;

  final double average;
  final double successRate; // percent
  final int notesCount;

  final List<String> activityLabels;
  final List<double> activityValues;

  final List<String> classLabels;
  final List<double> classValues;

  final Map<String, double> averageBySubject;

  ReportModel({
    required this.studentsCount,
    required this.teachersCount,
    required this.parentsCount,
    required this.classesCount,
    required this.average,
    required this.successRate,
    required this.notesCount,
    required this.activityLabels,
    required this.activityValues,
    required this.classLabels,
    required this.classValues,
    required this.averageBySubject,
  });
}
