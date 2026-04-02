import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../shared/models/models.dart';
import '../providers/level1_provider.dart';

class Level1TasksScreen extends ConsumerStatefulWidget {
  const Level1TasksScreen({super.key});
  @override
  ConsumerState<Level1TasksScreen> createState() => _Level1TasksScreenState();
}

class _Level1TasksScreenState extends ConsumerState<Level1TasksScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(myTasksProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myTasksProvider);
    final tasks = _filter == 'all'
        ? state.tasks
        : state.tasks.where((t) => t.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : tasks.isEmpty
                    ? _emptyState()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => ref.read(myTasksProvider.notifier).load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tasks.length,
                          itemBuilder: (_, i) => _taskCard(tasks[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['all', 'pending', 'in_progress', 'submitted', 'approved', 'rejected'];
    return Container(
      color: AppColors.surface,
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (_, i) {
          final f = filters[i];
          final sel = f == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(colors: AppColors.level1Gradient) : null,
                color: sel ? null : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? Colors.transparent : AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                f == 'all' ? 'All' : f[0].toUpperCase() + f.substring(1).replaceAll('_', ' '),
                style: TextStyle(
                    color: sel ? Colors.white : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _taskCard(TaskModel task) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(task.title,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  PriorityBadge(priority: task.priority),
                ],
              ),
              if (task.description != null) ...[
                const SizedBox(height: 8),
                Text(task.description!,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              if (task.instructions != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 14),
                      const SizedBox(width: 8),
                      Expanded(child: Text(task.instructions!,
                          style: const TextStyle(color: AppColors.info, fontSize: 12), maxLines: 3, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusBadge(status: task.status),
                  const SizedBox(width: 8),
                  if (task.dueDate != null) ...[
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(_formatDate(task.dueDate!),
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  if (task.paymentAmount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('₹${task.paymentAmount.toStringAsFixed(0)}',
                          style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (task.status == 'pending' || task.status == 'in_progress') ...[
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (task.status == 'pending')
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _startTask(task),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.level1Gradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.info.withOpacity(0.3), blurRadius: 8)],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Start Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (task.status == 'in_progress') ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showSubmitSheet(task),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: AppColors.primaryGradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('Submit Work', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    ),
  );

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return iso; }
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.4)),
        const SizedBox(height: 16),
        const Text('No tasks assigned yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Wait for admin to assign tasks', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    ),
  );

  Future<void> _startTask(TaskModel task) async {
    final ok = await ref.read(myTasksProvider.notifier).startTask(task.id);
    if (ok && mounted) showSuccessSnack(context, 'Task started! Now upload your work.');
  }

  void _showSubmitSheet(TaskModel task) {
    final notesCtrl = TextEditingController();
    List<PlatformFile> selectedFiles = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('📤 Submit Work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                Text('Task: ${task.title}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 20),
                AppTextField(controller: notesCtrl, label: 'Notes (optional)', prefixIcon: Icons.notes_rounded, maxLines: 3),
                const SizedBox(height: 16),
                // File picker
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      allowMultiple: true,
                      type: FileType.any,
                    );
                    if (result != null) setSt(() => selectedFiles = result.files);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_file_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          selectedFiles.isEmpty ? 'Pick Files (audio, video, doc, pdf…)' : '${selectedFiles.length} file(s) selected',
                          style: TextStyle(color: selectedFiles.isEmpty ? AppColors.textSecondary : AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...selectedFiles.map((f) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(f.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                        Text(_formatSize(f.size), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  )),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Submit',
                    icon: Icons.send_rounded,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final files = selectedFiles
                          .where((f) => f.path != null)
                          .map((f) => {'path': f.path!, 'name': f.name, 'mimeType': f.extension != null ? _mimeFromExt(f.extension!) : 'application/octet-stream'})
                          .toList();
                      final ok = await ref.read(mySubmissionsProvider.notifier).submitTask(
                        taskId: task.id,
                        notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                        files: files,
                      );
                      if (ok && mounted) {
                        ref.read(myTasksProvider.notifier).load();
                        showSuccessSnack(context, 'Work submitted successfully!');
                      } else if (mounted) {
                        showErrorSnack(context, 'Failed to submit. Please try again.');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3': case 'wav': case 'm4a': case 'ogg': return 'audio/$ext';
      case 'mp4': case 'mov': case 'avi': return 'video/$ext';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }
}
