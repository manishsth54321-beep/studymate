import 'package:flutter/material.dart';

import '../models/assignment.dart';
import '../utils/helpers.dart';

// one row in the assignment / task lists
class AssignmentTile extends StatelessWidget {
  final Assignment assignment;
  final String subjectName;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final bool showSubject;

  const AssignmentTile({
    super.key,
    required this.assignment,
    required this.subjectName,
    required this.onToggle,
    required this.onTap,
    this.showSubject = true,
  });

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final overdue = isOverdue(a);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(6, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: overdue ? overdueColor.withValues(alpha: 0.35) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: a.isCompleted,
              onChanged: (_) => onToggle(),
              activeColor: doneColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: a.isCompleted ? TextDecoration.lineThrough : null,
                      color: a.isCompleted ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (showSubject) ...[
                        Flexible(
                          child: Text(
                            subjectName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                          ),
                        ),
                        const Text("  •  ", style: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF))),
                      ],
                      Flexible(
                        child: Text(
                          a.isCompleted ? "Completed" : dueLabel(a.dueDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: overdue && !a.isCompleted
                                ? overdueColor
                                : const Color(0xFF6B7280),
                            fontWeight: overdue && !a.isCompleted ? FontWeight.w600 : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PriorityChip(priority: a.priority, muted: a.isCompleted),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String priority;
  final bool muted;

  const _PriorityChip({required this.priority, required this.muted});

  @override
  Widget build(BuildContext context) {
    final color = muted ? const Color(0xFF9CA3AF) : priorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            priority == "high" ? "High" : priority == "medium" ? "Medium" : "Low",
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
