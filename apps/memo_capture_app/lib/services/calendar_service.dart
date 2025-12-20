import '../models/memo.dart';

/// Placeholder for calendar integration.
///
/// In a production build this class should be swapped with an implementation
/// that uses `device_calendar`, `EventKit`, or the Android CalendarContract
/// APIs. For now, it just simulates a permission check and event creation so
/// the UI can be wired up.
class CalendarService {
  Future<bool> requestPermission() async {
    // TODO: Wire in `device_calendar` and handle permission prompts on both
    // Android and iOS.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return false;
  }

  Future<String?> createEvent(Memo memo) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    // TODO: Return the created event id when the native call is implemented.
    return null;
  }
}
