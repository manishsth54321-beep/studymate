import 'package:flutter_test/flutter_test.dart';
import 'package:studymate/models/assignment.dart';
import 'package:studymate/utils/helpers.dart';

Assignment make({
  required int dueDate,
  String status = "pending",
  String priority = "medium",
}) {
  return Assignment(
    id: "a1",
    subjectId: "s1",
    title: "Test work",
    description: "",
    dueDate: dueDate,
    priority: priority,
    status: status,
    createdAt: 0,
  );
}

int dayFromToday(int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.add(Duration(days: days)).millisecondsSinceEpoch;
}

void main() {
  group("Assignment Priority Algorithm", () {
    test("due today is high", () {
      expect(priorityFromDueDate(dayFromToday(0)), "high");
    });

    test("due tomorrow is high", () {
      expect(priorityFromDueDate(dayFromToday(1)), "high");
    });

    test("due in 3 days is medium", () {
      expect(priorityFromDueDate(dayFromToday(3)), "medium");
    });

    test("due in 7 days is medium", () {
      expect(priorityFromDueDate(dayFromToday(7)), "medium");
    });

    test("due in 8 days is low", () {
      expect(priorityFromDueDate(dayFromToday(8)), "low");
    });

    test("overdue stays high", () {
      expect(priorityFromDueDate(dayFromToday(-4)), "high");
    });
  });

  group("due label", () {
    test("today and tomorrow wording", () {
      expect(dueLabel(dayFromToday(0)), "Due: Today");
      expect(dueLabel(dayFromToday(1)), "Due: Tomorrow");
    });

    test("late tasks say overdue", () {
      expect(dueLabel(dayFromToday(-2)), "Overdue by 2 days");
      expect(dueLabel(dayFromToday(-1)), "Overdue by 1 day");
    });
  });

  group("Study Progress Calculation", () {
    test("empty list is 0", () {
      expect(progressOf([]), 0);
    });

    test("15 of 20 completed is 75 percent", () {
      final list = <Assignment>[];
      for (var i = 0; i < 20; i++) {
        list.add(make(dueDate: dayFromToday(i), status: i < 15 ? "completed" : "pending"));
      }
      expect(progressOf(list), 75);
    });

    test("all completed is 100", () {
      final list = [
        make(dueDate: dayFromToday(1), status: "completed"),
        make(dueDate: dayFromToday(2), status: "completed"),
      ];
      expect(progressOf(list), 100);
    });
  });

  group("overdue check", () {
    test("pending and late is overdue", () {
      expect(isOverdue(make(dueDate: dayFromToday(-1))), true);
    });

    test("completed is never overdue", () {
      expect(isOverdue(make(dueDate: dayFromToday(-1), status: "completed")), false);
    });

    test("future task is not overdue", () {
      expect(isOverdue(make(dueDate: dayFromToday(2))), false);
    });
  });

  group("duration label", () {
    test("minutes and hours", () {
      expect(durationLabel(45), "45m");
      expect(durationLabel(60), "1h");
      expect(durationLabel(90), "1h 30m");
    });
  });
}
