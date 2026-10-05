class Subject {
  String id;
  String name;
  String code;
  String description;
  int createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json["_id"] as String,
        name: (json["name"] ?? "") as String,
        code: (json["code"] ?? "") as String,
        description: (json["description"] ?? "") as String,
        createdAt: ((json["_creationTime"] ?? 0) as num).toInt(),
      );
}
