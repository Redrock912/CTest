import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/memo.dart';
import '../state/memo_controller.dart';
import 'widgets/memo_form_dialog.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Listen for messages from the notifier
    // We access the notifier lazily in a post-frame callback or use ref.listen in build
  }

  @override
  Widget build(BuildContext context) {
    // Listen for side-effects (messages)
    ref.listen<AsyncValue<List<Memo>>>(memoListProvider, (previous, next) {
      // This listener is for state changes, but we want the message stream.
      // We can access the notifier instance to listen to the stream.
    });

    // Better way: Listen to the notifier's stream exposed via a provider?
    // Or just listen in init via manual subscription?
    // Since MemoListNotifier is async, we get it via .notifier.

    // Using ref.listenManual on the provider to get the notifier is tricky if it's AsyncNotifier.
    // Instead, we can just watch a separate provider if we made one, OR:
    // We simply use a transient useEffect-style logic.

    final memos = ref.watch(memoListProvider);

    // HACK: To listen to the stream, we can hook it up here.
    // Ideally we would use a separate provider for "UserMessage" or "AppEvents".
    // For now, let's grab the notifier and listen.
    ref.listenManual(memoListProvider.notifier, (prev, next) {
        // This gives us the AsyncNotifier, but not the stream directly in a clean way unless we cast or expose it differently.
        // Actually, 'next' is the Notifier itself if we listen to .notifier?
        // No, ref.listen(provider.notifier) gives (previousNotifier, nextNotifier).
    });

    return _DashboardScaffold(memos: memos);
  }
}

class _DashboardScaffold extends ConsumerStatefulWidget {
  const _DashboardScaffold({required this.memos});
  final AsyncValue<List<Memo>> memos;

  @override
  ConsumerState<_DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends ConsumerState<_DashboardScaffold> {

  @override
  void initState() {
    super.initState();
    // We need to listen to the stream.
    // Since the notifier might be recreated, this is slightly fragile in pure Riverpod without a dedicated Event provider.
    // But let's try to access it once.

    // A robust pattern: Use a Provider for the stream.
    // But let's try to just use ref.read in the addPostFrameCallback once?
    WidgetsBinding.instance.addPostFrameCallback((_) {
       final notifier = ref.read(memoListProvider.notifier);
       notifier.messageStream.listen((message) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(message)),
           );
         }
       });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo Capture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(memoListProvider),
          ),
        ],
      ),
      body: widget.memos.when(
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
          child: Text('No memos yet. Share content to this app or add manually.'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: memos.length,
      itemBuilder: (context, index) {
        final memo = memos[index];
        final bool hasEvent = memo.calendarEventId != null;

        return Card(
          child: ListTile(
            title: Text(memo.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (memo.url.isNotEmpty && memo.url != 'No URL')
                  Text(memo.url, maxLines: 1, overflow: TextOverflow.ellipsis),

                if (memo.formattedRange != null)
                   Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Event: ${memo.formattedRange}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('Captured: ${memo.formattedDate}'),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasEvent)
                  const Icon(Icons.event, color: Colors.blue, size: 20)
                else
                  const SizedBox(height: 20),

                Icon(
                  memo.reviewed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: memo.reviewed ? Colors.green : Colors.grey,
                  size: 20,
                ),
              ],
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
                  if (memo.calendarEventId == null)
                    TextButton.icon(
                      onPressed: () async {
                        final eventId = await notifier.addToCalendar(memo);
                        if (!context.mounted) return;
                        if (eventId != null) {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to calendar')),
                           );
                           Navigator.of(context).pop();
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not add to calendar (missing date range or permission)')),
                           );
                        }
                      },
                      icon: const Icon(Icons.event_available),
                      label: const Text('Add to calendar'),
                    )
                  else
                     TextButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.event_available, color: Colors.green),
                      label: const Text('On Calendar'),
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
