import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import 'progress_screen.dart';
import 'sessions_screen.dart';

// the "More" tab - profile, reports, sessions, about, logout
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.name ?? "Student";
    final email = auth.email ?? "";

    return Scaffold(
      appBar: AppBar(title: const Text("More")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // profile card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFF1D4ED8),
                  child: Text(
                    name.isNotEmpty ? name.characters.first.toUpperCase() : "?",
                    style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16.5, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                      Text(email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _tile(
            icon: Icons.insights_outlined,
            color: const Color(0xFF2563EB),
            title: "Progress & Reports",
            subtitle: "Subject-wise charts and statistics",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen())),
          ),
          _tile(
            icon: Icons.timer_outlined,
            color: const Color(0xFF7C3AED),
            title: "Study Sessions",
            subtitle: "Log and review your study time",
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen())),
          ),
          _tile(
            icon: Icons.info_outline,
            color: const Color(0xFF0891B2),
            title: "About StudyMate",
            subtitle: "Version 1.0",
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("About StudyMate"),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("StudyMate v1.0"),
                    SizedBox(height: 8),
                    Text(
                      "A personal academic management app that helps students "
                      "organize subjects, assignments, deadlines and study time.",
                    ),
                    SizedBox(height: 8),
                    Text("BCA 6th Semester Project"),
                    Text("Made by Admin"),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // logout
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Color(0xFFFECACA)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text("Logout", style: TextStyle(fontSize: 15)),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Logout?"),
                  content: const Text("You will need to login again to open your data."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Logout", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                context.read<DataProvider>().clear();
                await context.read<AuthProvider>().logout();
              }
            },
          ),
          const SizedBox(height: 18),

          const Center(
            child: Text(
              "StudyMate v1.0\nBCA 6th Semester Project • Made by Admin",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _tile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280))),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF9CA3AF)),
      ),
    );
  }
}
