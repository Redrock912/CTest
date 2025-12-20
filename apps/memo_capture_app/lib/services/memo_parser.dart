import '../models/memo.dart';

class MemoParserResult {
  MemoParserResult({required this.memo, this.detectedDate});

  final Memo memo;
  final DateTime? detectedDate;
}

class MemoParser {
  static final _datePatterns = <RegExp>[
    RegExp(r"(?<month>\d{1,2})/(?<day>\d{1,2})\s+(?<hour>\d{1,2})(:(?<minute>\d{2}))?\s*(?<ampm>am|pm)?",
        caseSensitive: false),
    RegExp(
      r"(?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)\s+(?<day>\d{1,2})\s+(?<hour>\d{1,2})(:(?<minute>\d{2}))?\s*(?<ampm>am|pm)?",
      caseSensitive: false,
    ),
    RegExp(r"(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})[ T](?<hour>\d{2}):(?<minute>\d{2})"),
  ];

  MemoParserResult buildMemo({
    required String url,
    String? text,
    DateTime? manualDate,
  }) {
    final detectedDate = manualDate ?? _parseDateFromText(text ?? '');
    final now = DateTime.now();
    final memo = Memo(
      id: now.microsecondsSinceEpoch.toString(),
      url: url.trim(),
      title: _deriveTitle(url, text),
      memoText: text?.trim() ?? '',
      createdAt: now,
      detectedDateTime: detectedDate,
    );

    return MemoParserResult(memo: memo, detectedDate: detectedDate);
  }

  String _deriveTitle(String url, String? text) {
    if (text != null && text.trim().isNotEmpty) {
      final firstLine = text.trim().split('\n').first;
      if (firstLine.length <= 60) return firstLine;
      return '${firstLine.substring(0, 57)}...';
    }
    return url;
  }

  DateTime? _parseDateFromText(String text) {
    for (final pattern in _datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final now = DateTime.now();
          final year = int.tryParse(match.namedGroup('year') ?? '') ?? now.year;
          final monthText = match.namedGroup('month');
          final day = int.tryParse(match.namedGroup('day') ?? '');
          final hourText = match.namedGroup('hour');
          if (day == null || hourText == null) continue;

          final month = _monthFrom(monthText);
          var hour = int.tryParse(hourText) ?? 0;
          final minute = int.tryParse(match.namedGroup('minute') ?? '0') ?? 0;
          final ampm = match.namedGroup('ampm');
          if (ampm != null) {
            final lower = ampm.toLowerCase();
            if (lower == 'pm' && hour < 12) hour += 12;
            if (lower == 'am' && hour == 12) hour = 0;
          }
          return DateTime(year, month, day, hour, minute);
        } catch (_) {
          continue;
        }
      }
    }
    return null;
  }

  int _monthFrom(String? source) {
    if (source == null) {
      return DateTime.now().month;
    }
    final numeric = int.tryParse(source);
    if (numeric != null) return numeric;

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
