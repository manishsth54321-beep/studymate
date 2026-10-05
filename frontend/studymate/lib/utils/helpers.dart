import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/assignment.dart';

// priority colours used in the list and chips
const Color highPriorityColor = Color(0xFFEF4444);
const Color mediumPriorityColor = Color(0xFFF59E0B);
const Color lowPriorityColor = Color(0xFF10B981);

const Color doneColor = Color(0xFF22C55E);
const Color overdueColor = Color(0xFFDC2626);

// ---------------------------------------------------------------------------
// Algorithm 1: Assignment Priority Algorithm (from my report)
// due today/tomorrow -> high, within 7 days -> medium, after 7 days -> low
// ---------------------------------------------------------------------------

String priorityFromDueDate(int dueMs) {
  final left = daysLeft(dueMs);
  if (left <= 1) return "high";
  if (left <= 7) return "medium";
  return "low";
}

int daysLeft(int dueMs) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime.fromMillisecondsSinceEpoch(dueMs);
  final dueDay = DateTime(due.year, due.month, due.day);
  return dueDay.difference(today).inDays;
}

// "Due: Today" / "Due: Tomorrow" / "Due: 18 Oct" / "Overdue by 2 days"
String dueLabel(int dueMs) {
  final left = daysLeft(dueMs);
  if (left < 0) {
    final n = -left;
    return "Overdue by $n day${n == 1 ? "" : "s"}";
  }
  if (left == 0) return "Due: Today";
  if (left == 1) return "Due: Tomorrow";
  return "Due: ${DateFormat("d MMM").format(DateTime.fromMillisecondsSinceEpoch(dueMs))}";
}

// label used on the dashboard upcoming section
String dueInLabel(int dueMs) {
  final left = daysLeft(dueMs);
  if (left <= 1) return dueLabel(dueMs);
  if (left <= 7) return "Due in $left days";
  return dueLabel(dueMs);
}

String priorityLabel(String priority) {
  if (priority == "high") return "High Priority";
  if (priority == "medium") return "Medium Priority";
  return "Low Priority";
}

Color priorityColor(String priority) {
  if (priority == "high") return highPriorityColor;
  if (priority == "medium") return mediumPriorityColor;
  return lowPriorityColor;
}

bool isOverdue(Assignment a) => a.status == "pending" && daysLeft(a.dueDate) < 0;

// ---------------------------------------------------------------------------
// Algorithm 2: Study Progress Calculation
// Progress = Completed Assignments / Total Assignments * 100
// ---------------------------------------------------------------------------

double progressOf(List<Assignment> list) {
  if (list.isEmpty) return 0;
  final done = list.where((a) => a.status == "completed").length;
  return done / list.length * 100;
}

String percentLabel(double value) => "${value.toStringAsFixed(0)}%";

// 90 -> "1h 30m"
String durationLabel(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return "${m}m";
  if (m == 0) return "${h}h";
  return "${h}h ${m}m";
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return "Good morning";
  if (hour < 17) return "Good afternoon";
  return "Good evening";
}

// stable avatar colour for a subject, based on its name
Color subjectColor(String name) {
  const colors = [
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFFEA580C),
    Color(0xFF16A34A),
    Color(0xFF4F46E5),
  ];
  var sum = 0;
  for (final rune in name.runes) {
    sum += rune;
  }
  return colors[sum % colors.length];
}
