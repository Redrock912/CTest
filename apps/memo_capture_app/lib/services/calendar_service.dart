import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/memo.dart';

class CalendarService {
  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  CalendarService() {
    tz.initializeTimeZones();
  }

  Future<bool> requestPermission() async {
    // Check general calendar permissions first
    var status = await Permission.calendarFullAccess.status;
    if (!status.isGranted) {
      status = await Permission.calendarFullAccess.request();
    }

    // Fallback for iOS specific granular permissions if needed,
    // but typically the plugin handles this.
    // Also check via the plugin itself
    var permissions = await _deviceCalendarPlugin.hasPermissions();
    if (permissions.isSuccess && !permissions.data!) {
      permissions = await _deviceCalendarPlugin.requestPermissions();
    }

    return status.isGranted || (permissions.data ?? false);
  }

  Future<String?> createEvent(Memo memo) async {
    if (!memo.hasValidRange) return null;

    final permissionsGranted = await requestPermission();
    if (!permissionsGranted) return null;

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      return null;
    }

    // Pick a default writable calendar
    final calendar = calendarsResult.data!.firstWhere(
      (c) => (c.isDefault ?? false) && (c.isReadOnly == false),
      orElse: () => calendarsResult.data!.firstWhere(
        (c) => c.isReadOnly == false,
        orElse: () => calendarsResult.data!.first,
      ),
    );

    if (calendar.id == null) return null;

    // Set timezone
    String currentTimeZone = 'UTC';
    try {
      currentTimeZone = await FlutterTimezone.getLocalTimezone();
    } catch (_) {}

    final loc = tz.getLocation(currentTimeZone);

    final event = Event(
      calendar.id,
      title: memo.title,
      description: memo.url + '\n\n' + memo.memoText,
      start: tz.TZDateTime.from(memo.startDateTime!, loc),
      end: tz.TZDateTime.from(memo.endDateTime!, loc),
    );

    final createResult = await _deviceCalendarPlugin.createOrUpdateEvent(event);
    if (createResult.isSuccess && createResult.data != null) {
      return createResult.data;
    }
    return null;
  }
}
