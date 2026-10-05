class StudySession {
  String id;
  String subjectId;
  int duration; // minutes
  int studyDate; // ms timestamp
  int createdAt;

  StudySession({
    required this.id,
    required this.subjectId,
    required this.duration,
    required this.studyDate,
    required this.createdAt,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json["_id"] as String,
        subjectId: (json["subjectId"] ?? "") as String,
        duration: ((json["duration"] ?? 0) as num).toInt(),
        studyDate: ((json["studyDate"] ?? 0) as num).toInt(),
        createdAt: ((json["_creationTime"] ?? 0) as num).toInt(),
      );
}
