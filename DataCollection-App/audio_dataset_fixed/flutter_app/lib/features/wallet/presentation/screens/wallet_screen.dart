import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final walletTxnsProvider = FutureProvider<List<WalletTxnModel>>((ref) async {
  final r = await ApiClient.instance.get(ApiConstants.walletTransactions);
  return (r.data['data'] as List)
      .map((e) => WalletTxnModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final txnsAsync = ref.watch(walletTxnsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.invalidate(walletTxnsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(walletTxnsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildBalanceCard(auth),
              const SizedBox(height: 24),
              _buildEarningInfo(),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Transaction History'),
              const SizedBox(height: 14),
              txnsAsync.when(
                data: (txns) => txns.isEmpty
                    ? _emptyTxns()
                    : Column(children: txns.map((t) => _txnTile(t)).toList()),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AuthState auth) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: AppColors.walletGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Balance', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  '₹${(auth.user?.walletBalance ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Icon(Icons.person_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(auth.user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text(auth.user?.role.toUpperCase() ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, letterSpacing: 1)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildEarningInfo() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.success.withOpacity(0.25)),
    ),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.success, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Payments are automatically credited when admin approves your submission.',
            style: TextStyle(color: AppColors.success, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _txnTile(WalletTxnModel t) {
    final isCredit = t.transactionType == 'credit';
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
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description ?? (isCredit ? 'Credit' : 'Debit'),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(_formatDate(t.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}₹${t.amount.toStringAsFixed(2)}',
                style: TextStyle(
                    color: isCredit ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text('₹${t.balanceAfter.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return iso; }
  }

  Widget _emptyTxns() => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('No transactions yet', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    ),
  );
}
