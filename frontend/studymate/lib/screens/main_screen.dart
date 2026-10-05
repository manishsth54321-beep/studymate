import 'package:flutter/material.dart';

import 'assignments_screen.dart';
import 'dashboard_screen.dart';
import 'more_screen.dart';
import 'subjects_screen.dart';

// the 4 tabs at the bottom: Home / Subjects / Assignments / More
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    SubjectsScreen(),
    AssignmentsScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: "Subjects"),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: "Assignments"),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: "More"),
        ],
      ),
    );
  }
}
