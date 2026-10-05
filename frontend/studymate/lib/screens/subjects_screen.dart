import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../providers/data_provider.dart';
import '../utils/helpers.dart';

// subject management - add / edit / delete
class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("My Subjects")),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "addSubjectFab",
        onPressed: () => _showSubjectDialog(context, null),
        icon: const Icon(Icons.add),
        label: const Text("Add Subject"),
      ),
      body: RefreshIndicator(
        onRefresh: () => data.loadAll(),
        child: data.subjects.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  Icon(Icons.menu_book_outlined, size: 56, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 12),
                  Text(
                    "No subjects yet.\nTap 'Add Subject' to create your first one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                itemCount: data.subjects.length,
                itemBuilder: (context, i) {
                  final s = data.subjects[i];
                  final total = data.assignmentCountFor(s.id);
                  final done = data.completedCountFor(s.id);
                  final progress = data.progressForSubject(s.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: subjectColor(s.name),
                              child: Text(
                                s.code.isNotEmpty
                                    ? s.code.characters.first.toUpperCase()
                                    : s.name.isNotEmpty
                                        ? s.name.characters.first.toUpperCase()
                                        : "?",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                        fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                                  ),
                                  if (s.code.isNotEmpty)
                                    Text(
                                      s.code,
                                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                                    ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == "edit") {
                                  _showSubjectDialog(context, s);
                                } else {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Delete subject?"),
                                      content: Text(
                                          "All assignments and study sessions of '${s.name}' will be deleted too."),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text("Cancel")),
                                        TextButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text("Delete",
                                                style: TextStyle(color: Colors.red))),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    final err = await context.read<DataProvider>().deleteSubject(s.id);
                                    if (err != null && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(err)));
                                    }
                                  }
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: "edit", child: Text("Edit")),
                                PopupMenuItem(
                                    value: "delete",
                                    child: Text("Delete", style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                        if (s.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            s.description,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: total == 0 ? 0 : progress / 100,
                                  minHeight: 7,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              total == 0 ? "No assignments" : "$done/$total • ${percentLabel(progress)}",
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  // add + edit share the same dialog
  static Future<void> _showSubjectDialog(BuildContext context, Subject? existing) async {
    final nameController = TextEditingController(text: existing?.name ?? "");
    final codeController = TextEditingController(text: existing?.code ?? "");
    final descController = TextEditingController(text: existing?.description ?? "");
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? "Add Subject" : "Edit Subject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: "Subject name *"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: "Code (e.g. BCA-301)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Description"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  setDialogState(() => error = "Subject name is required");
                  return;
                }
                final data = context.read<DataProvider>();
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);

                String? err;
                if (existing == null) {
                  err = await data.addSubject(
                    name: nameController.text.trim(),
                    code: codeController.text.trim(),
                    description: descController.text.trim(),
                  );
                } else {
                  existing
                    ..name = nameController.text.trim()
                    ..code = codeController.text.trim()
                    ..description = descController.text.trim();
                  err = await data.updateSubject(existing);
                }

                if (err != null) {
                  setDialogState(() => error = err);
                } else {
                  navigator.pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text(existing == null ? "Subject added" : "Subject updated")),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
