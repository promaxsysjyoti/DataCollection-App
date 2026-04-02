import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/level1_provider.dart';

class Level1SubmissionsScreen extends ConsumerStatefulWidget {
  const Level1SubmissionsScreen({super.key});
  @override
  ConsumerState<Level1SubmissionsScreen> createState() => _Level1SubmissionsScreenState();
}

class _Level1SubmissionsScreenState extends ConsumerState<Level1SubmissionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(mySubmissionsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mySubmissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Submissions'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.read(mySubmissionsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : state.submissions.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(mySubmissionsProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.submissions.length,
                    itemBuilder: (_, i) => _submissionCard(state.submissions[i]),
                  ),
                ),
    );
  }

  Widget _submissionCard(SubmissionModel sub) {
    final Color statusColor;
    final IconData statusIcon;
    switch (sub.status) {
      case 'approved':
        statusColor = AppColors.success; statusIcon = Icons.check_circle_rounded; break;
      case 'rejected':
        statusColor = AppColors.error; statusIcon = Icons.cancel_rounded; break;
      default:
        statusColor = AppColors.warning; statusIcon = Icons.hourglass_empty_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: sub.status != 'pending' ? 1.5 : 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.taskTitle ?? 'Task',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(_formatDate(sub.createdAt),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                StatusBadge(status: sub.status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sub.notes != null && sub.notes!.isNotEmpty) ...[
                  _infoBox(Icons.notes_rounded, 'Your Notes', sub.notes!, AppColors.info),
                  const SizedBox(height: 10),
                ],
                if (sub.adminRemarks != null && sub.adminRemarks!.isNotEmpty) ...[
                  _infoBox(
                    Icons.admin_panel_settings_rounded,
                    'Admin Remarks',
                    sub.adminRemarks!,
                    sub.status == 'approved' ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(height: 10),
                ],
                if (sub.files.isNotEmpty) ...[
                  Text('Uploaded Files (${sub.files.length})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: sub.files.map((f) => _fileChip(f)).toList(),
                  ),
                ],
                if (sub.status == 'approved') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: AppColors.successGradient),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text('Payment has been credited to your wallet!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String content, Color color) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text(content, style: TextStyle(color: color.withOpacity(0.9), fontSize: 12)),
      ],
    ),
  );

  Widget _fileChip(SubmissionFileModel f) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_fileIcon(f.mimeType), size: 12, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(
          f.originalFilename.length > 16 ? '${f.originalFilename.substring(0, 13)}…' : f.originalFilename,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );

  IconData _fileIcon(String? mime) {
    if (mime == null) return Icons.attach_file_rounded;
    if (mime.startsWith('audio')) return Icons.audio_file_rounded;
    if (mime.startsWith('video')) return Icons.video_file_rounded;
    if (mime.startsWith('image')) return Icons.image_rounded;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_rounded;
    return Icons.description_rounded;
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  Widget _emptyState() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.upload_file_outlined, size: 64, color: AppColors.textMuted),
        SizedBox(height: 16),
        Text('No submissions yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        SizedBox(height: 8),
        Text('Complete tasks and submit your work', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    ),
  );
}
