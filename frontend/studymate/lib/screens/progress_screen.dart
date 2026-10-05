import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../utils/helpers.dart';
import '../widgets/progress_ring.dart';

// screen 5 in my report - progress and reports
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    // subjects that actually have assignments
    final withWork =
        data.subjects.where((s) => data.assignmentCountFor(s.id) > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Study Progress")),
      body: RefreshIndicator(
        onRefresh: () => data.loadAll(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // overall progress
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  ProgressRing(percent: data.progressPercent, size: 140, stroke: 13, caption: "completed"),
                  const SizedBox(height: 12),
                  const Text(
                    "Progress = Completed Assignments / Total Assignments × 100",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _countBox("Completed", "${data.completedCount}", doneColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _countBox("Pending", "${data.pendingCount}", mediumPriorityColor),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _countBox("Overdue", "${data.overdueCount}", overdueColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // subject wise progress
            const Text(
              "Subject-wise Progress",
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            if (withWork.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  "No assignments yet, so there is nothing to show here.",
                  style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    for (final s in withWork) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                            ),
                          ),
                          Text(
                            percentLabel(data.progressForSubject(s.id)),
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: data.progressForSubject(s.id) / 100,
                          minHeight: 9,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // study time
            const Text(
              "Study Time",
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.timer_outlined, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${durationLabel(data.minutesStudiedThisWeek())} this week",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const Text(
                        "Logged in study sessions",
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _countBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}
