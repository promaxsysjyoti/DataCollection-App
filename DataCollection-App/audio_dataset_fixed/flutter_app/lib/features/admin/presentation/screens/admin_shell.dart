import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import 'admin_home_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_submissions_screen.dart';
import 'admin_users_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  final _screens = const [
    AdminHomeScreen(),
    AdminTasksScreen(),
    AdminSubmissionsScreen(),
    AdminUsersScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: const Border(top: BorderSide(color: AppColors.border)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5))],
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
            _navItem(1, Icons.assignment_rounded, 'Tasks'),
            _navItem(2, Icons.upload_file_rounded, 'Submissions'),
            _navItem(3, Icons.people_rounded, 'Users'),
            _navItem(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(int idx, IconData icon, String label) {
    final selected = _index == idx;
    return GestureDetector(
      onTap: () => setState(() => _index = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: AppColors.adminGradient) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: selected ? Colors.white : AppColors.textMuted),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? Colors.white : AppColors.textMuted,
            )),
          ],
        ),
      ),
    );
  }
}
