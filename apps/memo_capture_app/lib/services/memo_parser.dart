import '../models/memo.dart';

class MemoParserResult {
  MemoParserResult({required this.memo, this.start, this.end});

  final Memo memo;
  final DateTime? start;
  final DateTime? end;
}

class MemoParser {
  // Regex to detect date/time patterns.

  // Pattern 1: Month Name (Jan 25)
  static final _monthNamePattern = RegExp(
    r"(?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)[a-z]*\s+(?<day>\d{1,2})",
    caseSensitive: false,
  );

  // Pattern 2: MM/DD or YYYY-MM-DD
  static final _numericDatePattern = RegExp(
     r"((?<year>\d{4})[-/])?(?<month>\d{1,2})[-/](?<day>\d{1,2})"
  );

  // Pattern 3: Time (5:00 PM, 5pm, 17:00)
  static final _timePattern = RegExp(
     r"(?<hour>\d{1,2})(:(?<minute>\d{2}))?\s*(?<ampm>am|pm)?",
     caseSensitive: false,
  );

  MemoParserResult buildMemo({
    required String url,
    String? text,
    DateTime? manualDate,
  }) {
    final range = manualDate != null
      ? _Range(manualDate, manualDate.add(const Duration(hours: 1)))
      : _parseRangeFromText(text ?? '');

    final now = DateTime.now();
    final memo = Memo(
      id: now.microsecondsSinceEpoch.toString(),
      url: url.trim(),
      title: _deriveTitle(url, text),
      memoText: text?.trim() ?? '',
      createdAt: now,
      startDateTime: range?.start,
      endDateTime: range?.end,
    );

    return MemoParserResult(memo: memo, start: range?.start, end: range?.end);
  }

  String _deriveTitle(String url, String? text) {
    if (text != null && text.trim().isNotEmpty) {
      final firstLine = text.trim().split('\n').first;
      if (firstLine.length <= 60) return firstLine;
      return '${firstLine.substring(0, 57)}...';
    }
    return url;
  }

  _Range? _parseRangeFromText(String text) {
    // 1. Find Date Component
    DateTime? date;
    int dateEndIndex = 0;

    final monthMatch = _monthNamePattern.firstMatch(text);
    if (monthMatch != null) {
      final now = DateTime.now();
      final month = _monthFrom(monthMatch.namedGroup('month'));
      final day = int.tryParse(monthMatch.namedGroup('day') ?? '') ?? 1;
      date = DateTime(now.year, month, day);
      dateEndIndex = monthMatch.end;
    } else {
      final numericMatch = _numericDatePattern.firstMatch(text);
      if (numericMatch != null) {
         final now = DateTime.now();
         final year = int.tryParse(numericMatch.namedGroup('year') ?? '') ?? now.year;
         final month = int.tryParse(numericMatch.namedGroup('month') ?? '') ?? 1;
         final day = int.tryParse(numericMatch.namedGroup('day') ?? '') ?? 1;
         date = DateTime(year, month, day);
         dateEndIndex = numericMatch.end;
      }
    }

    if (date == null) return null;

    // 2. Find Start Time AFTER the date
    final remainingText = text.substring(dateEndIndex);

    // Look for first time
    final startMatch = _timePattern.firstMatch(remainingText);
    if (startMatch == null) return null; // Date found but no time -> No range

    final start = _combineDateAndTime(date, startMatch);
    if (start == null) return null;

    // 3. Find End Time AFTER the start time
    // Look for optional separator like "-", "to"
    final afterStartText = remainingText.substring(startMatch.end);

    final endMatch = RegExp(r"^\s*(-|to)?\s*(?<hour>\d{1,2})(:(?<minute>\d{2}))?\s*(?<ampm>am|pm)?", caseSensitive: false).firstMatch(afterStartText);

    if (endMatch != null) {
       // We found a potential end time
       // However, we need to ensure the end match actually contains a time capture group.
       // The regex above duplicates _timePattern logic but anchors it.
       // If the group 'hour' is present, it's a time.
       if (endMatch.namedGroup('hour') != null) {
          final end = _combineDateAndTime(date, endMatch); // Assumes same day

          if (end != null) {
             DateTime finalEnd = end;
             // Handle PM inference and overnight wrapping
             // 1. PM Inference: Start 5pm, End 7 (implies 7pm)
             if (start.hour >= 12 && finalEnd.hour < 12 && endMatch.namedGroup('ampm') == null) {
                if (finalEnd.hour < start.hour - 12) {
                   // e.g. Start 5pm (17), End 2 (2). 2 is not < 5.
                } else {
                   finalEnd = finalEnd.add(const Duration(hours: 12));
                }
             }

             // 2. Overnight: 11pm - 1am
             if (finalEnd.isBefore(start)) {
                finalEnd = finalEnd.add(const Duration(days: 1));
             }

             return _Range(start, finalEnd);
          }
       }
    }

    // No end time found. Return incomplete range (Start only).
    return _Range(start, null);
  }

  DateTime? _combineDateAndTime(DateTime date, RegExpMatch match) {
    try {
      var hour = int.tryParse(match.namedGroup('hour') ?? '0') ?? 0;
      final minute = int.tryParse(match.namedGroup('minute') ?? '0') ?? 0;
      final ampm = match.namedGroup('ampm');

      if (ampm != null) {
        final lower = ampm.toLowerCase();
        if (lower == 'pm' && hour < 12) hour += 12;
        if (lower == 'am' && hour == 12) hour = 0;
      }
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  int _monthFrom(String? source) {
    if (source == null) {
      return DateTime.now().month;
    }
    final lookup = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'sept': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return lookup[source.toLowerCase()] ?? DateTime.now().month;
  }
}

class _Range {
  _Range(this.start, this.end);
  final DateTime start;
  final DateTime? end;
}
