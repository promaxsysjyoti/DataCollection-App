import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/level1_provider.dart';

class Level1HomeScreen extends ConsumerStatefulWidget {
  const Level1HomeScreen({super.key});
  @override
  ConsumerState<Level1HomeScreen> createState() => _Level1HomeScreenState();
}

class _Level1HomeScreenState extends ConsumerState<Level1HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(l1DashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final dash = ref.watch(l1DashboardProvider);
    final d    = dash.data;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(l1DashboardProvider.notifier).load(),
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
                    _buildWelcomeBanner(auth, d),
                    const SizedBox(height: 24),
                    _buildTaskStatsGrid(d),
                    const SizedBox(height: 24),
                    _buildSubmissionStats(d),
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
            gradient: const LinearGradient(colors: AppColors.level1Gradient),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text('My Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _buildWelcomeBanner(AuthState auth, Map<String, dynamic> d) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: AppColors.level1Gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: AppColors.info.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${auth.user?.fullName.split(' ').first ?? 'User'}! 🎙️',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('You have ${d['pending_tasks'] ?? 0} pending tasks',
                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Wallet: ₹${((d['wallet_balance'] ?? 0) as num).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
        ),
      ],
    ),
  );

  Widget _buildTaskStatsGrid(Map<String, dynamic> d) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SectionHeader(title: 'Task Overview'),
      const SizedBox(height: 14),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: [
          GradientCard(title: 'Total Tasks', value: '${d['total_tasks'] ?? 0}', icon: Icons.assignment_rounded, gradient: AppColors.primaryGradient),
          GradientCard(title: 'Pending', value: '${d['pending_tasks'] ?? 0}', icon: Icons.pending_rounded, gradient: AppColors.warningGradient),
          GradientCard(title: 'Approved', value: '${d['approved_tasks'] ?? 0}', icon: Icons.check_circle_rounded, gradient: AppColors.successGradient),
          GradientCard(title: 'Rejected', value: '${d['rejected_tasks'] ?? 0}', icon: Icons.cancel_rounded, gradient: [AppColors.error, AppColors.accent]),
        ],
      ),
    ],
  );

  Widget _buildSubmissionStats(Map<String, dynamic> d) {
    final pending  = (d['pending_submissions'] ?? 0) as int;
    final approved = (d['approved_submissions'] ?? 0) as int;
    final rejected = (d['rejected_submissions'] ?? 0) as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Submission Status'),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _statItem('Pending', pending, AppColors.warning),
              _divider(),
              _statItem('Approved', approved, AppColors.success),
              _divider(),
              _statItem('Rejected', rejected, AppColors.error),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statItem(String label, int count, Color color) => Expanded(
    child: Column(
      children: [
        Text('$count', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ],
    ),
  );

  Widget _divider() => Container(width: 1, height: 40, color: AppColors.border);

  Widget _buildRecentTasks(Map<String, dynamic> d) {
    final list = (d['recent_tasks'] as List?) ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Recent Tasks'),
        const SizedBox(height: 14),
        ...list.map((t) {
          final task = t as Map<String, dynamic>;
          return Container(
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
                  child: const Icon(Icons.assignment_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['title'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      if (task['payment_amount'] != null && (task['payment_amount'] as num) > 0)
                        Text('₹${task['payment_amount']}', style: const TextStyle(color: AppColors.success, fontSize: 11)),
                    ],
                  ),
                ),
                StatusBadge(status: task['status'] ?? 'pending'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShimmer() => Column(
    children: List.generate(4, (i) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShimmerBox(width: double.infinity, height: 80),
    )),
  );
}
