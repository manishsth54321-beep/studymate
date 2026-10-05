import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/data_provider.dart';
import '../utils/helpers.dart';

// study session log - part of the study_sessions table in my schema
class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _minutesController = TextEditingController(text: "30");
  String? _subjectId;
  bool _saving = false;

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _log() async {
    final data = context.read<DataProvider>();
    if (_subjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select a subject first")),
      );
      return;
    }
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    if (minutes <= 0 || minutes > 1440) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter minutes between 1 and 1440")),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final err = await data.addSession(
      subjectId: _subjectId!,
      duration: minutes,
      studyDate: DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logged ${durationLabel(minutes)} of study time")),
      );
    }
  }

  Future<void> _quickLog(int minutes) async {
    _minutesController.text = "$minutes";
    await _log();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final today = DateTime.now();
    final todayMs = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;

    // reset if the chosen subject was deleted in another screen
    if (_subjectId == null || !data.subjects.any((s) => s.id == _subjectId)) {
      _subjectId = data.subjects.isEmpty ? null : data.subjects.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Study Sessions")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // log form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Log a study session",
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (data.subjects.isEmpty)
                  const Text(
                    "Add a subject first, then you can log study time.",
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
                  )
                else ...[
                  DropdownButtonFormField<String>(
                    key: ValueKey(_subjectId),
                    initialValue: _subjectId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: "Subject"),
                    items: data.subjects
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _subjectId = v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minutesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Minutes", hintText: "30"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _saving ? null : _log,
                        child: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text("Log"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(label: const Text("15 min"), onPressed: _saving ? null : () => _quickLog(15)),
                      ActionChip(label: const Text("30 min"), onPressed: _saving ? null : () => _quickLog(30)),
                      ActionChip(label: const Text("60 min"), onPressed: _saving ? null : () => _quickLog(60)),
                      ActionChip(label: const Text("120 min"), onPressed: _saving ? null : () => _quickLog(120)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // today summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.today, color: Colors.white70),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      durationLabel(data.minutesStudiedOn(todayMs)),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text("studied today",
                        style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      durationLabel(data.minutesStudiedThisWeek()),
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text("this week",
                        style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text("History",
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          if (data.sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No study sessions logged yet.",
                style: TextStyle(fontSize: 13.5, color: Color(0xFF6B7280)),
              ),
            )
          else
            ...data.sessions.map((s) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 20, color: Color(0xFF2563EB)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.subjectName(s.subjectId),
                              style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827))),
                          Text(
                            DateFormat("d MMM yyyy").format(DateTime.fromMillisecondsSinceEpoch(s.studyDate)),
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    Text(durationLabel(s.duration),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827))),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF9CA3AF)),
                      onPressed: () async {
                        final err = await context.read<DataProvider>().deleteSession(s.id);
                        if (err != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                        }
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
