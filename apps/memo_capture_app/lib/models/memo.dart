import 'package:intl/intl.dart';

class Memo {
  const Memo({
    required this.id,
    required this.url,
    required this.title,
    required this.memoText,
    required this.createdAt,
    this.startDateTime,
    this.endDateTime,
    this.reviewed = false,
    this.calendarEventId,
  });

  final String id;
  final String url;
  final String title;
  final String memoText;
  final DateTime createdAt;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final bool reviewed;
  final String? calendarEventId;

  /// Returns true if a valid range (start and end) is present.
  bool get hasValidRange => startDateTime != null && endDateTime != null;

  String get formattedDate =>
      DateFormat('yMMMd').add_jm().format(createdAt.toLocal());

  String? get formattedRange {
    if (startDateTime == null) return null;
    final start = DateFormat('yMMMd').add_jm().format(startDateTime!.toLocal());
    if (endDateTime == null) return '$start - ?';
    final end = DateFormat('yMMMd').add_jm().format(endDateTime!.toLocal());
    return '$start - $end';
  }

  Memo copyWith({
    String? id,
    String? url,
    String? title,
    String? memoText,
    DateTime? createdAt,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? reviewed,
    String? calendarEventId,
  }) {
    return Memo(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      memoText: memoText ?? this.memoText,
      createdAt: createdAt ?? this.createdAt,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      reviewed: reviewed ?? this.reviewed,
      calendarEventId: calendarEventId ?? this.calendarEventId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'memoText': memoText,
      'createdAt': createdAt.toIso8601String(),
      'startDateTime': startDateTime?.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'reviewed': reviewed,
      'calendarEventId': calendarEventId,
    };
  }

  factory Memo.fromJson(Map<String, dynamic> json) {
    // Migration: if 'detectedDateTime' exists in old data, map it to startDateTime
    DateTime? start;
    if (json.containsKey('startDateTime')) {
      start = json['startDateTime'] == null
          ? null
          : DateTime.parse(json['startDateTime'] as String);
    } else if (json.containsKey('detectedDateTime')) {
      start = json['detectedDateTime'] == null
          ? null
          : DateTime.parse(json['detectedDateTime'] as String);
    }

    return Memo(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      memoText: json['memoText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDateTime: start,
      endDateTime: json['endDateTime'] == null
          ? null
          : DateTime.parse(json['endDateTime'] as String),
      reviewed: json['reviewed'] as bool? ?? false,
      calendarEventId: json['calendarEventId'] as String?,
    );
  }
}
