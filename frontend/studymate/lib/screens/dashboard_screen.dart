import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../utils/helpers.dart';
import '../widgets/assignment_tile.dart';
import '../widgets/progress_ring.dart';
import 'assignment_form_screen.dart';

// screen 2 in my report - dashboard / home
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();

    final firstName = (auth.name ?? "Student").split(" ").first;
    final today = data.todayTasks.take(4).toList();
    final upcoming = data.upcoming.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => data.loadAll(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // greeting header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${greeting()}, $firstName 👋",
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Keep going, you're doing great!",
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Icon(Icons.notifications_none, size: 22, color: Color(0xFF374151)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (data.loading && data.assignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                // ---------------------------------------------------------
                // Today's Tasks
                // ---------------------------------------------------------
                _sectionTitle("Today's Tasks", right: Text("${data.todayTasks.length} due")),
                const SizedBox(height: 8),
                if (today.isEmpty)
                  _emptyCard("No tasks due today 🎉")
                else
                  ...today.map(
                    (a) => AssignmentTile(
                      assignment: a,
                      subjectName: data.subjectName(a.subjectId),
                      onToggle: () async {
                        final err = await context.read<DataProvider>().toggleStatus(a);
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(err)));
                        }
                      },
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AssignmentFormScreen(existing: a)),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),

                // ---------------------------------------------------------
                // Upcoming (next 3 by due date)
                // ---------------------------------------------------------
                _sectionTitle("Upcoming"),
                const SizedBox(height: 8),
                if (upcoming.isEmpty)
                  _emptyCard("Nothing upcoming. Add an assignment to get started.")
                else
                  ...upcoming.map((a) => _UpcomingCard(
                        subjectName: data.subjectName(a.subjectId),
                        title: a.title,
                        label: dueInLabel(a.dueDate),
                        priority: a.priority,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AssignmentFormScreen(existing: a)),
                        ),
                      )),
                const SizedBox(height: 14),

                // ---------------------------------------------------------
                // Progress
                // ---------------------------------------------------------
                _sectionTitle("Progress"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      ProgressRing(percent: data.progressPercent, size: 104),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          children: [
                            _statRow(doneColor, "Completed", "${data.completedCount}"),
                            const SizedBox(height: 8),
                            _statRow(mediumPriorityColor, "Pending", "${data.pendingCount}"),
                            const SizedBox(height: 8),
                            _statRow(const Color(0xFF2563EB), "Subjects", "${data.subjects.length}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _sectionTitle(String text, {Widget? right}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(text, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        if (right != null)
          DefaultTextStyle(
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
            child: right,
          ),
      ],
    );
  }

  static Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B7280))),
    );
  }

  static Widget _statRow(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151)))),
        Text(value, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
      ],
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final String subjectName;
  final String title;
  final String label;
  final String priority;
  final VoidCallback onTap;

  const _UpcomingCard({
    required this.subjectName,
    required this.title,
    required this.label,
    required this.priority,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = priorityColor(priority);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.event_note_outlined, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$subjectName • $label",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
