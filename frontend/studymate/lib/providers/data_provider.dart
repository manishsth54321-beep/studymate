import 'package:flutter/foundation.dart';

import '../models/assignment.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../utils/api.dart';
import '../utils/helpers.dart';

// holds all subjects / assignments / study sessions for the logged in user
class DataProvider extends ChangeNotifier {
  Api _api = Api();

  List<Subject> subjects = [];
  List<Assignment> assignments = [];
  List<StudySession> sessions = [];

  bool loading = false;
  String? error;

  void setToken(String? token) {
    _api = Api(token: token);
  }

  Future<bool> loadAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final s = await _api.post("/api/subjects/list", {});
      final a = await _api.post("/api/assignments/list", {});
      final ss = await _api.post("/api/sessions/list", {});

      subjects = (s["subjects"] as List).map((e) => Subject.fromJson(e)).toList();
      assignments = (a["assignments"] as List).map((e) => Assignment.fromJson(e)).toList();
      sessions = (ss["sessions"] as List).map((e) => StudySession.fromJson(e)).toList();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // wipe everything when the user logs out
  void clear() {
    subjects = [];
    assignments = [];
    sessions = [];
    setToken(null);
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // subjects
  // -----------------------------------------------------------------------

  Future<String?> addSubject({
    required String name,
    required String code,
    required String description,
  }) async {
    try {
      await _api.post("/api/subjects/add", {
        "name": name,
        "code": code,
        "description": description,
      });
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateSubject(Subject subject) async {
    try {
      await _api.post("/api/subjects/update", {
        "id": subject.id,
        "name": subject.name,
        "code": subject.code,
        "description": subject.description,
      });
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteSubject(String id) async {
    try {
      await _api.post("/api/subjects/delete", {"id": id});
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // -----------------------------------------------------------------------
  // assignments
  // -----------------------------------------------------------------------

  Future<String?> addAssignment(Assignment a) async {
    try {
      await _api.post("/api/assignments/add", a.toJson()..remove("id"));
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateAssignment(Assignment a) async {
    try {
      await _api.post("/api/assignments/update", a.toJson());
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteAssignment(String id) async {
    try {
      await _api.post("/api/assignments/delete", {"id": id});
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // flips pending <-> completed, updates the screen immediately
  Future<String?> toggleStatus(Assignment a) async {
    final old = a.status;
    a.status = old == "completed" ? "pending" : "completed";
    notifyListeners();
    try {
      await _api.post("/api/assignments/status", {
        "id": a.id,
        "status": a.status,
      });
      return null;
    } on ApiException catch (e) {
      a.status = old;
      notifyListeners();
      return e.message;
    }
  }

  // -----------------------------------------------------------------------
  // study sessions
  // -----------------------------------------------------------------------

  Future<String?> addSession({
    required String subjectId,
    required int duration,
    required int studyDate,
  }) async {
    try {
      await _api.post("/api/sessions/add", {
        "subjectId": subjectId,
        "duration": duration,
        "studyDate": studyDate,
      });
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteSession(String id) async {
    try {
      await _api.post("/api/sessions/delete", {"id": id});
      await loadAll();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  // -----------------------------------------------------------------------
  // helpers used by the dashboard / progress screens
  // -----------------------------------------------------------------------

  String subjectName(String subjectId) {
    for (final s in subjects) {
      if (s.id == subjectId) return s.name;
    }
    return "Subject";
  }

  // pending work that is due today or already late
  List<Assignment> get todayTasks {
    final list =
        assignments.where((a) => a.status == "pending" && daysLeft(a.dueDate) <= 0).toList();
    list.sort((x, y) => x.dueDate.compareTo(y.dueDate));
    return list;
  }

  // pending work sorted by nearest due date (Algorithm 3)
  List<Assignment> get upcoming {
    final list =
        assignments.where((a) => a.status == "pending" && daysLeft(a.dueDate) > 0).toList();
    list.sort((x, y) => x.dueDate.compareTo(y.dueDate));
    return list;
  }

  int get completedCount => assignments.where((a) => a.status == "completed").length;

  int get pendingCount => assignments.where((a) => a.status == "pending").length;

  int get overdueCount => assignments.where(isOverdue).length;

  double get progressPercent => progressOf(assignments);

  double progressForSubject(String subjectId) {
    final list = assignments.where((a) => a.subjectId == subjectId).toList();
    return progressOf(list);
  }

  int assignmentCountFor(String subjectId) =>
      assignments.where((a) => a.subjectId == subjectId).length;

  int completedCountFor(String subjectId) => assignments
      .where((a) => a.subjectId == subjectId && a.status == "completed")
      .length;

  int minutesStudiedOn(int dayMs) {
    final day = DateTime.fromMillisecondsSinceEpoch(dayMs);
    var total = 0;
    for (final s in sessions) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.studyDate);
      if (d.year == day.year && d.month == day.month && d.day == day.day) {
        total += s.duration;
      }
    }
    return total;
  }

  int minutesStudiedThisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var total = 0;
    for (final s in sessions) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.studyDate);
      if (today.difference(DateTime(d.year, d.month, d.day)).inDays < 7) {
        total += s.duration;
      }
    }
    return total;
  }
}
