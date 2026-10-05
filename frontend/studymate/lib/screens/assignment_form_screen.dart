import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/assignment.dart';
import '../providers/data_provider.dart';
import '../utils/helpers.dart';

// screen 3 in my report - add (and edit) an assignment
class AssignmentFormScreen extends StatefulWidget {
  final Assignment? existing;

  const AssignmentFormScreen({super.key, this.existing});

  @override
  State<AssignmentFormScreen> createState() => _AssignmentFormScreenState();
}

class _AssignmentFormScreenState extends State<AssignmentFormScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _subjectId;
  late DateTime _dueDate;
  String _priority = "auto"; // auto (from algorithm) / high / medium / low
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController.text = e?.title ?? "";
    _descController.text = e?.description ?? "";
    _subjectId = e?.subjectId;
    if (e != null) {
      _dueDate = DateTime.fromMillisecondsSinceEpoch(e.dueDate);
      _priority = e.priority;
    } else {
      _dueDate = DateTime.now().add(const Duration(days: 7));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // the algorithm decides the priority when left on "auto"
  String get _finalPriority =>
      _priority == "auto" ? priorityFromDueDate(_dueDate.millisecondsSinceEpoch) : _priority;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2031),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = "Title is required");
      return;
    }
    if (_subjectId == null) {
      setState(() => _error = "Please select a subject");
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    final data = context.read<DataProvider>();
    String? err;

    if (widget.existing == null) {
      final a = Assignment(
        id: "",
        subjectId: _subjectId!,
        title: title,
        description: _descController.text.trim(),
        dueDate: DateTime(_dueDate.year, _dueDate.month, _dueDate.day).millisecondsSinceEpoch,
        priority: _finalPriority,
        status: "pending",
        createdAt: 0,
      );
      err = await data.addAssignment(a);
    } else {
      widget.existing!
        ..subjectId = _subjectId!
        ..title = title
        ..description = _descController.text.trim()
        ..dueDate = DateTime(_dueDate.year, _dueDate.month, _dueDate.day).millisecondsSinceEpoch
        ..priority = _finalPriority;
      err = await data.updateAssignment(widget.existing!);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.existing == null ? "Assignment saved" : "Assignment updated")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    if (data.subjects.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.existing == null ? "Add Assignment" : "Edit Assignment")),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              "Please add a subject first,\nan assignment needs a subject.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.5, color: Color(0xFF6B7280)),
            ),
          ),
        ),
      );
    }

    // make sure a valid subject is selected
    if (_subjectId == null || !data.subjects.any((s) => s.id == _subjectId)) {
      _subjectId = data.subjects.first.id;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? "Add Assignment" : "Edit Assignment")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13.5)),
                ),

              _label("Title"),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(hintText: "DBMS Assignment"),
              ),
              const SizedBox(height: 16),

              _label("Subject"),
              DropdownButtonFormField<String>(
                key: ValueKey(_subjectId),
                initialValue: _subjectId,
                isExpanded: true,
                items: data.subjects
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _subjectId = v),
              ),
              const SizedBox(height: 16),

              _label("Description"),
              TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Write database design and queries...",
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              _label("Due Date"),
              TextField(
                readOnly: true,
                controller: TextEditingController(
                    text: DateFormat("d MMM yyyy").format(_dueDate)),
                decoration: InputDecoration(
                  hintText: "10 Oct 2026",
                  prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                  suffixIcon: TextButton(onPressed: _pickDate, child: const Text("Change")),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              _label("Priority"),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                items: const [
                  DropdownMenuItem(value: "auto", child: Text("Auto (based on due date)")),
                  DropdownMenuItem(value: "high", child: Text("High")),
                  DropdownMenuItem(value: "medium", child: Text("Medium")),
                  DropdownMenuItem(value: "low", child: Text("Low")),
                ],
                onChanged: (v) => setState(() => _priority = v ?? "auto"),
              ),
              const SizedBox(height: 8),
              // show what the algorithm picked
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: priorityColor(_finalPriority),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _priority == "auto"
                        ? "Algorithm says: ${priorityLabel(_finalPriority)}"
                        : priorityLabel(_finalPriority),
                    style: TextStyle(
                      fontSize: 13,
                      color: priorityColor(_finalPriority),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(dueLabel(_dueDate.millisecondsSinceEpoch),
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(widget.existing == null ? "Save" : "Update",
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      );
}
