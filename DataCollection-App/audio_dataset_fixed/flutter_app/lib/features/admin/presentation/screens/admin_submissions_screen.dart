import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/admin_provider.dart';

class AdminSubmissionsScreen extends ConsumerStatefulWidget {
  const AdminSubmissionsScreen({super.key});
  @override
  ConsumerState<AdminSubmissionsScreen> createState() => _AdminSubmissionsScreenState();
}

class _AdminSubmissionsScreenState extends ConsumerState<AdminSubmissionsScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(submissionsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(submissionsProvider);
    final subs = state.submissions.where((s) {
      if (_filter == 'all') return true;
      return s.status.toLowerCase() == _filter.toLowerCase();
    }).toList();

    final counts = {
      'all': state.submissions.length,
      'pending': state.submissions.where((s) => s.status == 'pending').length,
      'approved': state.submissions.where((s) => s.status == 'approved').length,
      'rejected': state.submissions.where((s) => s.status == 'rejected').length,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Row(children: [
          const Text('Submissions'),
          if (state.submissions.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${state.submissions.length}',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => ref.read(submissionsProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(children: [
        _buildFilterBar(counts),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : state.error != null
                  ? _buildErrorState(state.error!)
                  : subs.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () => ref.read(submissionsProvider.notifier).load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: subs.length,
                            itemBuilder: (_, i) => _buildSubmissionCard(subs[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar(Map<String, int> counts) {
    final filters = ['all', 'pending', 'approved', 'rejected'];
    return Container(
      color: AppColors.surface,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final sel = f == _filter;
          final cnt = counts[f] ?? 0;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(colors: AppColors.primaryGradient) : null,
                color: sel ? null : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? Colors.transparent : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1),
                    style: TextStyle(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                if (cnt > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: sel ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$cnt',
                        style: TextStyle(
                            color: sel ? Colors.white : AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ),
          );
        },
      ),
    );
  }

  // ── Card ───────────────────────────────────────────────────────────────────
  Widget _buildSubmissionCard(SubmissionModel sub) {
    final isPending = sub.status == 'pending';
    final isApproved = sub.status == 'approved';
    Color borderColor = AppColors.border;
    if (isPending) borderColor = AppColors.warning.withOpacity(0.5);
    if (isApproved) borderColor = AppColors.success.withOpacity(0.4);
    if (sub.status == 'rejected') borderColor = AppColors.error.withOpacity(0.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isPending ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        _buildCardHeader(sub),
        if (sub.notes != null && sub.notes!.isNotEmpty)
          _buildInfoBox(Icons.notes_rounded, 'User Notes', sub.notes!, AppColors.info),
        if (sub.adminRemarks != null && sub.adminRemarks!.isNotEmpty)
          _buildInfoBox(
            Icons.admin_panel_settings_rounded,
            'Admin Remarks',
            sub.adminRemarks!,
            isApproved ? AppColors.success : AppColors.error,
          ),
        _buildFilesSection(sub),
        _buildActionButtons(sub),
      ]),
    );
  }

  Widget _buildCardHeader(SubmissionModel sub) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(sub.taskTitle ?? 'Task',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(sub.userName ?? 'Unknown',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              if (sub.userEmail != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text('• ${sub.userEmail}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text(_formatDate(sub.createdAt),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ),
        StatusBadge(status: sub.status),
      ]),
    );
  }

  Widget _buildInfoBox(IconData icon, String title, String content, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(content, style: TextStyle(color: color.withOpacity(0.9), fontSize: 13)),
        ])),
      ]),
    );
  }

  // ── Files Section ──────────────────────────────────────────────────────────
  Widget _buildFilesSection(SubmissionModel sub) {
    if (sub.files.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withOpacity(0.2)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 14),
          SizedBox(width: 8),
          Text('No files attached to this submission',
              style: TextStyle(color: AppColors.warning, fontSize: 12)),
        ]),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.folder_open_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Uploaded Files  (${sub.files.length})',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        ...sub.files.map((f) => _buildFileRow(f)),
      ]),
    );
  }

  Widget _buildFileRow(SubmissionFileModel f) {
    return GestureDetector(
      onTap: () => _showFileDetailsSheet(f),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(_fileIcon(f.mimeType), size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.originalFilename,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
            Row(children: [
              Text(_formatSize(f.fileSize),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              if (f.mimeType != null) ...[
                const Text('  •  ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(f.mimeType!.split('/').last.toUpperCase(),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Icon(Icons.visibility_rounded, size: 13, color: AppColors.primary),
              SizedBox(width: 4),
              Text('View', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── File Details Sheet ─────────────────────────────────────────────────────
  void _showFileDetailsSheet(SubmissionFileModel f) {
    final fileUrl = f.fileUrl != null
        ? '${ApiConstants.baseUrl}${f.fileUrl}'
        : '${ApiConstants.baseUrl}/uploads/submissions/${f.filename}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          // File icon + name
          Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.primaryGradient),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_fileIcon(f.mimeType), color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.originalFilename,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                  overflow: TextOverflow.ellipsis),
              Text(_formatSize(f.fileSize),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ])),
          ]),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border),
          const SizedBox(height: 12),
          // Details
          _detailRow(Icons.file_present_rounded, 'File Name', f.filename),
          _detailRow(Icons.label_rounded, 'Original Name', f.originalFilename),
          _detailRow(Icons.data_usage_rounded, 'Size', _formatSize(f.fileSize)),
          _detailRow(Icons.category_rounded, 'MIME Type', f.mimeType ?? 'Unknown'),
          _detailRow(Icons.access_time_rounded, 'Uploaded', _formatDate(f.createdAt)),
          const SizedBox(height: 12),
          // Server path box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.storage_rounded, size: 13, color: AppColors.primary),
                SizedBox(width: 6),
                Text('Server Location', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 6),
              Text(fileUrl,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, color: AppColors.info, size: 15),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Files are physically stored on the server at:\nbackend/uploads/submissions/<submission_id>/\n\nThey are publicly accessible via the /uploads endpoint.',
                style: TextStyle(color: AppColors.info, fontSize: 12),
              )),
            ]),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(width: 100, child: Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600))),
        Expanded(child: Text(value,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            overflow: TextOverflow.ellipsis, maxLines: 2)),
      ]),
    );
  }

  // ── Action Buttons ─────────────────────────────────────────────────────────
  Widget _buildActionButtons(SubmissionModel sub) {
    final isPending = sub.status == 'pending';
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(12),
      child: isPending
          ? Row(children: [
              Expanded(flex: 2, child: _actionBtn(
                label: 'Approve', icon: Icons.check_circle_rounded, color: AppColors.success,
                onTap: () => _showReviewDialog(sub, approve: true),
              )),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: _actionBtn(
                label: 'Reject', icon: Icons.cancel_rounded, color: AppColors.error,
                onTap: () => _showReviewDialog(sub, approve: false),
              )),
              const SizedBox(width: 8),
              _iconBtn(icon: Icons.delete_outline_rounded, color: AppColors.textMuted,
                  onTap: () => _confirmDelete(sub)),
            ])
          : Row(children: [
              Expanded(child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: (sub.status == 'approved' ? AppColors.success : AppColors.error).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(sub.status == 'approved' ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: sub.status == 'approved' ? AppColors.success : AppColors.error, size: 16),
                  const SizedBox(width: 6),
                  Text(sub.status == 'approved' ? 'Approved' : 'Rejected',
                      style: TextStyle(
                          color: sub.status == 'approved' ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              )),
              const SizedBox(width: 8),
              _iconBtn(icon: Icons.delete_outline_rounded, color: AppColors.error,
                  onTap: () => _confirmDelete(sub)),
            ]),
    );
  }

  Widget _actionBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 17),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ),
      );

  Widget _iconBtn({required IconData icon, required Color color, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      );

  // ── Review Dialog ──────────────────────────────────────────────────────────
  void _showReviewDialog(SubmissionModel sub, {required bool approve}) {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: (approve ? AppColors.success : AppColors.error).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(approve ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: approve ? AppColors.success : AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          Text(approve ? 'Approve Submission' : 'Reject Submission',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.assignment_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(child: Text(sub.taskTitle ?? '',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(sub.userName ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ]),
              if (sub.files.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.attach_file_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text('${sub.files.length} file(s) submitted',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: remarksCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: approve ? 'Great work! Add remarks (optional)…' : 'Reason for rejection (optional)…',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              filled: true, fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: approve ? AppColors.success : AppColors.error)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? AppColors.success : AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: Icon(approve ? Icons.check_rounded : Icons.close_rounded, size: 18),
            label: Text(approve ? 'Approve' : 'Reject',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () async {
              Navigator.pop(context);
              final status = approve ? 'approved' : 'rejected';
              final remarks = remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim();
              final ok = await ref.read(submissionsProvider.notifier).review(sub.id, status, remarks);
              if (mounted) {
                ok
                    ? showSuccessSnack(context,
                        approve ? '✅ Approved! Payment credited to user wallet.' : '❌ Submission rejected.')
                    : showErrorSnack(context, 'Failed to update. Please try again.');
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Delete Dialog ──────────────────────────────────────────────────────────
  void _confirmDelete(SubmissionModel sub) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Delete Submission',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          const Text('Are you sure you want to permanently delete this submission?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.07), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Task: ${sub.taskTitle ?? 'Unknown'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('By: ${sub.userName ?? 'Unknown'}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              if (sub.files.isNotEmpty)
                Text('${sub.files.length} file(s) will be deleted from server',
                    style: const TextStyle(color: AppColors.error, fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 10),
          const Text(
            '⚠ Cannot be undone. Task resets to "In Progress" so user can resubmit.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () async {
              Navigator.pop(context);
              final ok = await ref.read(submissionsProvider.notifier).delete(sub.id);
              if (mounted) {
                ok
                    ? showSuccessSnack(context, 'Submission deleted successfully.')
                    : showErrorSnack(context, 'Failed to delete. Please try again.');
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  IconData _fileIcon(String? mime) {
    if (mime == null) return Icons.attach_file_rounded;
    if (mime.startsWith('audio')) return Icons.audio_file_rounded;
    if (mime.startsWith('video')) return Icons.video_file_rounded;
    if (mime.startsWith('image')) return Icons.image_rounded;
    if (mime.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (mime.contains('word') || mime.contains('doc')) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) { return iso; }
  }

  Widget _buildEmptyState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 88, height: 88,
          decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.upload_file_outlined, size: 44, color: AppColors.textMuted)),
      const SizedBox(height: 20),
      Text(_filter == 'all' ? 'No submissions yet' : 'No ${_filter} submissions',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 17, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Level1 users\' work will appear here\nafter they submit tasks.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
    ]),
  );

  Widget _buildErrorState(String error) => Center(
    child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.error),
      const SizedBox(height: 16),
      const Text('Failed to load submissions',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text(error, style: const TextStyle(color: AppColors.textMuted, fontSize: 13), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: () => ref.read(submissionsProvider.notifier).load(),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Retry'),
      ),
    ])),
  );
}
