import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/admin_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(usersListProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Level 1 Users'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.read(usersListProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.users.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(usersListProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.users.length,
                    itemBuilder: (_, i) => _userCard(state.users[i]),
                  ),
                ),
    );
  }

  Widget _userCard(UserModel user) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Row(
          children: [
            _avatar(user),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(user.fullName,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (user.isActive ? AppColors.success : AppColors.error).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: user.isActive ? AppColors.success : AppColors.error,
                            fontSize: 10, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text('₹${user.walletBalance.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                      if (user.phone != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.phone_rounded, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(user.phone!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                'Topup Wallet', Icons.add_card_rounded, AppColors.success,
                () => _showTopupSheet(user),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                'View Profile', Icons.person_search_rounded, AppColors.info,
                () => _showUserProfile(user),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _avatar(UserModel user) {
    final initials = user.fullName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.level1Gradient),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );

  Widget _emptyState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.group_outlined, size: 64, color: AppColors.textMuted),
        SizedBox(height: 16),
        Text('No users found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
      ],
    ),
  );

  void _showTopupSheet(UserModel user) {
    final amountCtrl = TextEditingController();
    final descCtrl   = TextEditingController(text: 'Admin top-up');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('💰 Add Wallet Balance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('User: ${user.fullName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text('Current balance: ₹${user.walletBalance.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontSize: 13)),
            const SizedBox(height: 20),
            AppTextField(controller: amountCtrl, label: 'Amount (₹)', prefixIcon: Icons.currency_rupee_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            AppTextField(controller: descCtrl, label: 'Description', prefixIcon: Icons.notes_rounded),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                label: 'Add Balance',
                colors: AppColors.successGradient,
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) return;
                  Navigator.pop(context);
                  final ok = await ref.read(usersListProvider.notifier).topupWallet(user.id, amount, descCtrl.text);
                  if (ok && mounted) showSuccessSnack(context, '₹${amount.toStringAsFixed(0)} added to ${user.fullName}\'s wallet!');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Center(child: _avatar(user)),
              const SizedBox(height: 12),
              Center(child: Text(user.fullName, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800))),
              Center(child: Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
              const SizedBox(height: 20),
              _profileSection('Personal', [
                if (user.age != null) _profileRow('Age', '${user.age}'),
                if (user.gender != null) _profileRow('Gender', user.gender!),
                if (user.dateOfBirth != null) _profileRow('Date of Birth', user.dateOfBirth!),
                if (user.phone != null) _profileRow('Phone', user.phone!),
              ]),
              if (user.aadharNumber != null || user.panNumber != null)
                _profileSection('KYC Documents', [
                  if (user.aadharNumber != null) _profileRow('Aadhar', user.aadharNumber!),
                  if (user.panNumber != null) _profileRow('PAN', user.panNumber!),
                ]),
              if (user.bankName != null || user.bankAccountNumber != null)
                _profileSection('Bank Details', [
                  if (user.bankName != null) _profileRow('Bank', user.bankName!),
                  if (user.bankAccountNumber != null) _profileRow('Account No.', user.bankAccountNumber!),
                  if (user.bankIfsc != null) _profileRow('IFSC', user.bankIfsc!),
                  if (user.upiId != null) _profileRow('UPI ID', user.upiId!),
                ]),
              _profileSection('Wallet', [
                _profileRow('Balance', '₹${user.walletBalance.toStringAsFixed(2)}'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileSection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Column(children: rows),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _profileRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}
