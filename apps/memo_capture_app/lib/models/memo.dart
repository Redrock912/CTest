import 'package:intl/intl.dart';

class Memo {
  const Memo({
    required this.id,
    required this.url,
    required this.title,
    required this.memoText,
    required this.createdAt,
    this.detectedDateTime,
    this.reviewed = false,
    this.calendarEventId,
  });

  final String id;
  final String url;
  final String title;
  final String memoText;
  final DateTime createdAt;
  final DateTime? detectedDateTime;
  final bool reviewed;
  final String? calendarEventId;

  String get formattedDate =>
      DateFormat('yMMMd').add_jm().format(createdAt.toLocal());

  String? get formattedDetectedDate => detectedDateTime == null
      ? null
      : DateFormat('yMMMd').add_jm().format(detectedDateTime!.toLocal());

  Memo copyWith({
    String? id,
    String? url,
    String? title,
    String? memoText,
    DateTime? createdAt,
    DateTime? detectedDateTime,
    bool? reviewed,
    String? calendarEventId,
  }) {
    return Memo(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      memoText: memoText ?? this.memoText,
      createdAt: createdAt ?? this.createdAt,
      detectedDateTime: detectedDateTime ?? this.detectedDateTime,
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
      'detectedDateTime': detectedDateTime?.toIso8601String(),
      'reviewed': reviewed,
      'calendarEventId': calendarEventId,
    };
  }

  factory Memo.fromJson(Map<String, dynamic> json) {
    return Memo(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      memoText: json['memoText'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      detectedDateTime: json['detectedDateTime'] == null
          ? null
          : DateTime.parse(json['detectedDateTime'] as String),
      reviewed: json['reviewed'] as bool? ?? false,
      calendarEventId: json['calendarEventId'] as String?,
    );
  }
}
