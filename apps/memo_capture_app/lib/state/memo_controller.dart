import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
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

  // Stream to communicate messages to the UI (e.g. Success Toast)
  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  @override
  Future<List<Memo>> build() async {
    _storage = await ref.watch(memoStorageProvider.future);
    _parser = MemoParser();
    final saved = await _storage.load();
    saved.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Initialize sharing listener
    _initSharingListener();

    // Dispose controller when provider is destroyed
    ref.onDispose(() {
      _messageController.close();
    });

    return saved;
  }

  void _initSharingListener() {
    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedContent(value.first);
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
       if (value.isNotEmpty) {
        _handleSharedContent(value.first);
        ReceiveSharingIntent.instance.reset();
      }
    });
  }

  Future<void> _handleSharedContent(SharedMediaFile media) async {
     final content = media.path;
     if (content.isEmpty) return;

     String url = '';
     String? description = content;

     final uriTry = Uri.tryParse(content);
     if (uriTry != null && (uriTry.scheme == 'http' || uriTry.scheme == 'https')) {
       url = content;
       description = null;
     } else {
       final urlReg = RegExp(r'(https?://\S+)');
       final match = urlReg.firstMatch(content);
       if (match != null) {
         url = match.group(0)!;
         description = content;
       } else {
         url = 'No URL';
       }
     }

     await addMemo(url: url, description: description, autoClose: true);
  }

  Future<void> addMemo({
    required String url,
    String? description,
    DateTime? manualDate,
    bool autoClose = false,
  }) async {
    final parsed = _parser.buildMemo(url: url, text: description, manualDate: manualDate);

    // Auto-Export Logic
    Memo memo = parsed.memo;
    if (parsed.memo.hasValidRange) {
       try {
         final eventId = await addToCalendar(parsed.memo);
         if (eventId != null) {
           memo = memo.copyWith(calendarEventId: eventId);
         }
       } catch (_) {
         // Ignore calendar errors to ensure local save succeeds
       }
    }

    final updated = [...state.value ?? <Memo>[], memo]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncData(updated);
    await _storage.save(updated);

    if (autoClose) {
      _messageController.add("Memo saved!");
      await Future<void>.delayed(const Duration(seconds: 2));
      SystemNavigator.pop();
    }
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
