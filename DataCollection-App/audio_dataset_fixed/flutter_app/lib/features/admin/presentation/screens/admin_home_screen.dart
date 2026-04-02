import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminDashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final auth  = ref.watch(authProvider);
    final dash  = ref.watch(adminDashboardProvider);
    final d     = dash.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(adminDashboardProvider.notifier).load(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(auth),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (dash.isLoading && d == null)
                    _buildShimmer()
                  else if (d != null) ...[
                    _buildWelcomeBanner(auth),
                    const SizedBox(height: 24),
                    _buildStatsGrid(d),
                    const SizedBox(height: 24),
                    _buildSubmissionStats(d),
                    const SizedBox(height: 24),
                    _buildRecentSubmissions(d),
                    const SizedBox(height: 24),
                    _buildRecentTasks(d),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthState auth) => SliverAppBar(
    expandedHeight: 0,
    floating: true,
    backgroundColor: AppColors.surface,
    elevation: 0,
    title: Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.adminGradient),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text('Admin Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    ),
    actions: [
      Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.circle, color: AppColors.success, size: 8),
            SizedBox(width: 6),
            Text('Live', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ],
  );

  Widget _buildWelcomeBanner(AuthState auth) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: AppColors.adminGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good ${_greeting()}, ${auth.user?.fullName.split(' ').first ?? 'Admin'}! 👋',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Manage your team\'s tasks & submissions',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.insights_rounded, color: Colors.white, size: 28),
        ),
      ],
    ),
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildStatsGrid(Map<String, dynamic> d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(title: 'Overview'),
      const SizedBox(height: 14),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          GradientCard(title: 'Total Users', value: '${d['total_users'] ?? 0}', icon: Icons.people_rounded, gradient: AppColors.level1Gradient),
          GradientCard(title: 'Total Tasks', value: '${d['total_tasks'] ?? 0}', icon: Icons.assignment_rounded, gradient: AppColors.adminGradient),
          GradientCard(title: 'Pending Tasks', value: '${d['pending_tasks'] ?? 0}', icon: Icons.pending_rounded, gradient: AppColors.warningGradient),
          GradientCard(title: 'Disbursed', value: '₹${((d['total_wallet_disbursed'] ?? 0) as num).toStringAsFixed(0)}', icon: Icons.account_balance_wallet_rounded, gradient: AppColors.walletGradient),
        ],
      ),
    ],
  );

  Widget _buildSubmissionStats(Map<String, dynamic> d) {
    final pending  = (d['pending_submissions'] ?? 0) as int;
    final approved = (d['approved_submissions'] ?? 0) as int;
    final rejected = (d['rejected_submissions'] ?? 0) as int;
    final total = pending + approved + rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Submission Status'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _statPill('Pending', pending, AppColors.warning),
                  const SizedBox(width: 8),
                  _statPill('Approved', approved, AppColors.success),
                  const SizedBox(width: 8),
                  _statPill('Rejected', rejected, AppColors.error),
                ],
              ),
              if (total > 0) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        if (pending > 0) Expanded(flex: pending, child: Container(color: AppColors.warning)),
                        if (approved > 0) Expanded(flex: approved, child: Container(color: AppColors.success)),
                        if (rejected > 0) Expanded(flex: rejected, child: Container(color: AppColors.error)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statPill(String label, int count, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
        ],
      ),
    ),
  );

  Widget _buildRecentSubmissions(Map<String, dynamic> d) {
    final list = (d['recent_submissions'] as List?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Submissions'),
        const SizedBox(height: 14),
        ...list.map((s) => _submissionTile(s as Map<String, dynamic>)),
      ],
    );
  }

  Widget _submissionTile(Map<String, dynamic> s) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.upload_file_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s['task_title'] ?? 'Task', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(s['user_name'] ?? 'User', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        StatusBadge(status: s['status'] ?? 'pending'),
      ],
    ),
  );

  Widget _buildRecentTasks(Map<String, dynamic> d) {
    final list = (d['recent_tasks'] as List?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Tasks'),
        const SizedBox(height: 14),
        ...list.map((t) => _taskTile(t as Map<String, dynamic>)),
      ],
    );
  }

  Widget _taskTile(Map<String, dynamic> t) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.assignment_rounded, color: AppColors.secondary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              if (t['assignee_name'] != null)
                Text('→ ${t['assignee_name']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        StatusBadge(status: t['status'] ?? 'pending'),
      ],
    ),
  );

  Widget _buildShimmer() => Column(
    children: List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShimmerBox(width: double.infinity, height: 80),
    )),
  );
}
