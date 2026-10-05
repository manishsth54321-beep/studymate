class Assignment {
  String id;
  String subjectId;
  String title;
  String description;
  int dueDate; // ms timestamp of the due day
  String priority; // high / medium / low
  String status; // pending / completed
  int createdAt;

  Assignment({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
        id: json["_id"] as String,
        subjectId: (json["subjectId"] ?? "") as String,
        title: (json["title"] ?? "") as String,
        description: (json["description"] ?? "") as String,
        dueDate: ((json["dueDate"] ?? 0) as num).toInt(),
        priority: (json["priority"] ?? "medium") as String,
        status: (json["status"] ?? "pending") as String,
        createdAt: ((json["_creationTime"] ?? 0) as num).toInt(),
      );

  bool get isCompleted => status == "completed";

  // body used for add/update calls
  Map<String, dynamic> toJson() => {
        "id": id,
        "subjectId": subjectId,
        "title": title,
        "description": description,
        "dueDate": dueDate,
        "priority": priority,
        "status": status,
      };
}
