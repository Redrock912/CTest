import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memo.dart';
import '../state/memo_controller.dart';
import 'widgets/memo_form_dialog.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memos = ref.watch(memoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo Capture (base)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(memoListProvider),
          ),
        ],
      ),
      body: memos.when(
        data: (data) => _MemoList(memos: data),
        error: (error, stack) => Center(
          child: Text('Failed to load memos: $error'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleAddMemo(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add memo'),
      ),
    );
  }

  Future<void> _handleAddMemo(BuildContext context, WidgetRef ref) async {
    final result = await MemoFormDialog.show(context);
    if (result == null) return;
    await ref.read(memoListProvider.notifier).addMemo(
          url: result.url,
          description: result.description,
          manualDate: result.manualDate,
        );
  }
}

class _MemoList extends ConsumerWidget {
  const _MemoList({required this.memos});

  final List<Memo> memos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (memos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No memos yet. Use the + button to add one.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: memos.length,
      itemBuilder: (context, index) {
        final memo = memos[index];
        return Card(
          child: ListTile(
            title: Text(memo.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(memo.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (memo.formattedDetectedDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Detected: ${memo.formattedDetectedDate}'),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Saved: ${memo.formattedDate}'),
                ),
              ],
            ),
            trailing: Icon(
              memo.reviewed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: memo.reviewed ? Colors.green : Colors.grey,
            ),
            onTap: () => _showMemoActions(context, ref, memo),
          ),
        );
      },
    );
  }

  Future<void> _showMemoActions(
    BuildContext context,
    WidgetRef ref,
    Memo memo,
  ) async {
    final notifier = ref.read(memoListProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(memo.memoText.isEmpty ? 'No description' : memo.memoText),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  TextButton.icon(
                    onPressed: () => notifier.openUrl(memo.url),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open link'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      notifier.updateReviewed(memo.id, !memo.reviewed);
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      memo.reviewed ? Icons.undo : Icons.check_circle,
                    ),
                    label: Text(memo.reviewed ? 'Mark pending' : 'Mark reviewed'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final eventId = await notifier.addToCalendar(memo);
                      if (!context.mounted) return;
                      final message = eventId == null
                          ? 'Calendar integration not wired yet'
                          : 'Created calendar event ($eventId)';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    },
                    icon: const Icon(Icons.event_available),
                    label: const Text('Add to calendar'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      notifier.deleteMemo(memo.id);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
