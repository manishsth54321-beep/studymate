import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/assignment.dart';
import '../providers/data_provider.dart';
import '../widgets/assignment_tile.dart';
import 'assignment_form_screen.dart';

// screen 4 in my report - list with search + subject/status/priority filter
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final _searchController = TextEditingController();

  String _status = "all"; // all / pending / completed
  String _subjectFilter = "all";
  String _priorityFilter = "all";
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Assignment> _filtered(DataProvider data) {
    final list = data.assignments.where((a) {
      if (_status == "pending" && a.status != "pending") return false;
      if (_status == "completed" && a.status != "completed") return false;
      if (_subjectFilter != "all" && a.subjectId != _subjectFilter) return false;
      if (_priorityFilter != "all" && a.priority != _priorityFilter) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!a.title.toLowerCase().contains(q) && !a.description.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    // pending first (nearest due date), completed at the end
    list.sort((x, y) {
      if (x.status != y.status) return x.status == "pending" ? -1 : 1;
      return x.dueDate.compareTo(y.dueDate);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    // if the filtered subject was deleted, go back to "all subjects"
    if (_subjectFilter != "all" && !data.subjects.any((s) => s.id == _subjectFilter)) {
      _subjectFilter = "all";
    }

    final items = _filtered(data);

    return Scaffold(
      appBar: AppBar(title: const Text("My Assignments")),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "addAssignmentFab",
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AssignmentFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text("Add Assignment"),
      ),
      body: Column(
        children: [
          // search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Search assignments...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = "");
                        },
                      ),
              ),
            ),
          ),

          // status tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _statusChip("All", "all"),
                const SizedBox(width: 8),
                _statusChip("Pending", "pending"),
                const SizedBox(width: 8),
                _statusChip("Completed", "completed"),
              ],
            ),
          ),

          // subject + priority dropdowns
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_subjectFilter),
                    initialValue: _subjectFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      labelText: "Subject",
                    ),
                    items: [
                      const DropdownMenuItem(value: "all", child: Text("All subjects", overflow: TextOverflow.ellipsis)),
                      ...data.subjects.map((s) => DropdownMenuItem(
                            value: s.id,
                            child: Text(s.name, overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => setState(() => _subjectFilter = v ?? "all"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priorityFilter,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      labelText: "Priority",
                    ),
                    items: const [
                      DropdownMenuItem(value: "all", child: Text("All")),
                      DropdownMenuItem(value: "high", child: Text("High")),
                      DropdownMenuItem(value: "medium", child: Text("Medium")),
                      DropdownMenuItem(value: "low", child: Text("Low")),
                    ],
                    onChanged: (v) => setState(() => _priorityFilter = v ?? "all"),
                  ),
                ),
              ],
            ),
          ),

          // the list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => data.loadAll(),
              child: items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(24),
                      children: const [
                        SizedBox(height: 70),
                        Icon(Icons.assignment_outlined, size: 56, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 12),
                        Text(
                          "No assignments found.\nTap 'Add Assignment' to create one.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final a = items[i];
                        return AssignmentTile(
                          assignment: a,
                          subjectName: data.subjectName(a.subjectId),
                          onToggle: () async {
                            final err = await context.read<DataProvider>().toggleStatus(a);
                            if (err != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                            }
                          },
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AssignmentFormScreen(existing: a)),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    final selected = _status == value;
    return Expanded(
      child: FilterChip(
        label: Center(child: Text(label)),
        selected: selected,
        showCheckmark: false,
        selectedColor: const Color(0xFF1D4ED8),
        labelStyle: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF374151),
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: selected ? const Color(0xFF1D4ED8) : const Color(0xFFE5E7EB)),
        ),
        onSelected: (_) => setState(() => _status = value),
      ),
    );
  }
}
