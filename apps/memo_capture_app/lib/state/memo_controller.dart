import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../models/memo.dart';
import '../services/calendar_service.dart';
import '../services/memo_parser.dart';
import '../services/memo_storage.dart';

final memoStorageProvider = FutureProvider<MemoStorage>((ref) async {
  return MemoStorage.init();
});

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

final memoListProvider = AsyncNotifierProvider<MemoListNotifier, List<Memo>>(
  MemoListNotifier.new,
);

class MemoListNotifier extends AsyncNotifier<List<Memo>> {
  late MemoStorage _storage;
  late MemoParser _parser;

  @override
  Future<List<Memo>> build() async {
    _storage = await ref.watch(memoStorageProvider.future);
    _parser = MemoParser();
    final saved = await _storage.load();
    saved.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return saved;
  }

  Future<void> addMemo({
    required String url,
    String? description,
    DateTime? manualDate,
  }) async {
    final parsed = _parser.buildMemo(url: url, text: description, manualDate: manualDate);
    final updated = [...state.value ?? <Memo>[], parsed.memo]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncData(updated);
    await _storage.save(updated);
  }

  Future<void> updateReviewed(String id, bool reviewed) async {
    final current = state.value ?? <Memo>[];
    final updated = [
      for (final memo in current)
        if (memo.id == id) memo.copyWith(reviewed: reviewed) else memo,
    ];
    state = AsyncData(updated);
    await _storage.save(updated);
  }

  Future<void> deleteMemo(String id) async {
    final updated = (state.value ?? <Memo>[]).where((memo) => memo.id != id).toList();
    state = AsyncData(updated);
    await _storage.save(updated);
  }

  Future<String?> addToCalendar(Memo memo) async {
    final calendar = ref.read(calendarServiceProvider);
    final hasPermission = await calendar.requestPermission();
    if (!hasPermission) return null;
    final eventId = await calendar.createEvent(memo);
    if (eventId != null) {
      await _persistCalendarId(memo.id, eventId);
    }
    return eventId;
  }

  Future<void> _persistCalendarId(String id, String calendarId) async {
    final current = state.value ?? <Memo>[];
    final updated = [
      for (final memo in current)
        if (memo.id == id) memo.copyWith(calendarEventId: calendarId) else memo,
    ];
    state = AsyncData(updated);
    await _storage.save(updated);
  }

  Future<void> openUrl(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }
}
