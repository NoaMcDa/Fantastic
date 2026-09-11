import 'package:fantastic/features/adaptation/application/streak_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late StreakNotificationService service;
  late tz.Location israel;

  setUpAll(() {
    tz_data.initializeTimeZones();
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(tz.TZDateTime.now(tz.UTC));
  });

  setUp(() {
    israel = tz.getLocation(StreakNotificationService.timeZone);
    plugin = _MockPlugin();
    service = StreakNotificationService(plugin);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
      ),
    ).thenAnswer((_) async {});
  });

  group('nextReminderAfter', () {
    tz.TZDateTime at(int hour, int minute) =>
        tz.TZDateTime(israel, 2026, 9, 10, hour, minute);

    test('a morning launch schedules for this evening', () {
      final next = StreakNotificationService.nextReminderAfter(at(9, 0));

      expect(next, tz.TZDateTime(israel, 2026, 9, 10, 20));
    });

    // The case the issue's `isBefore` gets wrong: at exactly 20:00 it
    // schedules for 20:00, which has just arrived — the reminder fires
    // immediately and then nothing happens for a day.
    test('a launch at exactly the hour schedules for tomorrow', () {
      final next = StreakNotificationService.nextReminderAfter(at(20, 0));

      expect(next, tz.TZDateTime(israel, 2026, 9, 11, 20));
    });

    test('an evening launch after the hour schedules for tomorrow', () {
      final next = StreakNotificationService.nextReminderAfter(at(21, 30));

      expect(next, tz.TZDateTime(israel, 2026, 9, 11, 20));
    });

    test('a minute before the hour still schedules for today', () {
      final next = StreakNotificationService.nextReminderAfter(at(19, 59));

      expect(next, tz.TZDateTime(israel, 2026, 9, 10, 20));
    });

    test('rolls over a month boundary', () {
      final next = StreakNotificationService.nextReminderAfter(
        tz.TZDateTime(israel, 2026, 9, 30, 22),
      );

      expect(next, tz.TZDateTime(israel, 2026, 10, 1, 20));
    });

    test('rolls over a year boundary', () {
      final next = StreakNotificationService.nextReminderAfter(
        tz.TZDateTime(israel, 2026, 12, 31, 22),
      );

      expect(next, tz.TZDateTime(israel, 2027, 1, 1, 20));
    });

    test('stays in the zone it was given', () {
      final next = StreakNotificationService.nextReminderAfter(at(9, 0));

      expect(next.location, israel);
    });
  });

  group('scheduleDailyReminder', () {
    test('cancels the existing reminder before scheduling', () async {
      await service.scheduleDailyReminder();

      verify(() => plugin.cancel(id: StreakNotificationService.reminderId))
          .called(1);
    });

    test('schedules under the stable reminder id', () async {
      await service.scheduleDailyReminder();

      verify(
        () => plugin.zonedSchedule(
          id: StreakNotificationService.reminderId,
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        ),
      ).called(1);
    });

    /// The instant the reminder was scheduled for.
    Future<tz.TZDateTime> scheduledAt() async {
      await service.scheduleDailyReminder();
      return verify(
            () => plugin.zonedSchedule(
              id: any(named: 'id'),
              title: any(named: 'title'),
              body: any(named: 'body'),
              scheduledDate: captureAny(named: 'scheduledDate'),
              notificationDetails: any(named: 'notificationDetails'),
              androidScheduleMode: any(named: 'androidScheduleMode'),
              matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
            ),
          ).captured.single
          as tz.TZDateTime;
    }

    test('schedules for 20:00', () async {
      expect(
        (await scheduledAt()).hour,
        StreakNotificationService.reminderHour,
      );
    });

    // The bug this pin exists to prevent: an uninitialised `tz.local` is UTC,
    // which in Israel would fire the reminder at 22:00 or 23:00.
    test('schedules in the Israeli zone, not UTC', () async {
      final scheduled = await scheduledAt();

      expect(scheduled.location.name, 'Asia/Jerusalem');
      expect(scheduled.location, isNot(tz.UTC));
    });

    test('always schedules in the future', () async {
      final scheduled = await scheduledAt();

      expect(scheduled.isAfter(tz.TZDateTime.now(israel)), isTrue);
    });

    // Without this the notification fires once and never again.
    test('repeats daily by matching the time component', () async {
      await service.scheduleDailyReminder();

      verify(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          matchDateTimeComponents: DateTimeComponents.time,
        ),
      ).called(1);
    });

    test('the copy is Hebrew', () {
      // Any Hebrew letter. Copy that silently reverted to English would
      // otherwise ship unnoticed.
      final hebrew = RegExp(r'[֐-׿]');
      expect(hebrew.hasMatch(StreakNotificationService.title), isTrue);
      expect(hebrew.hasMatch(StreakNotificationService.body), isTrue);
    });
  });

  test('cancelDailyReminder cancels the same id', () async {
    await service.cancelDailyReminder();

    verify(() => plugin.cancel(id: StreakNotificationService.reminderId))
        .called(1);
  });
}
