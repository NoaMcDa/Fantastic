import 'package:fantastic/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockIOSPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

class _MockMacOSPlugin extends Mock
    implements MacOSFlutterLocalNotificationsPlugin {}

class _MockAndroidPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late _MockIOSPlugin ios;
  late _MockMacOSPlugin macos;
  late _MockAndroidPlugin android;
  late NotificationService service;

  setUpAll(() => registerFallbackValue(const InitializationSettings()));

  setUp(() {
    plugin = _MockPlugin();
    ios = _MockIOSPlugin();
    macos = _MockMacOSPlugin();
    android = _MockAndroidPlugin();
    service = NotificationService(plugin);
    when(() => plugin.initialize(settings: any(named: 'settings')))
        .thenAnswer((_) async => true);
    when(
      plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >,
    ).thenReturn(ios);
    when(
      plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin
      >,
    ).thenReturn(macos);
    when(
      plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >,
    ).thenReturn(android);
  });

  // `flutter test` reports `defaultTargetPlatform` as android regardless of
  // the host, so a suite that wants another platform has to say so — and has
  // to put it back, or it leaks into every test that follows.
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  // These run on the VM, where kIsWeb is a const false, so they exercise the
  // native branch. The web branch is a single early return, and CI's
  // `flutter build web` is what proves it compiles.
  group('initialise', () {
    test('initialises the plugin', () async {
      await service.initialise();

      verify(() => plugin.initialize(settings: any(named: 'settings')))
          .called(1);
    });

    test('reports that the platform supports notifications', () async {
      expect(await service.initialise(), isTrue);
    });

    /// The settings handed to the plugin.
    InitializationSettings captured() =>
        verify(() => plugin.initialize(settings: captureAny(named: 'settings')))
                .captured
                .single
            as InitializationSettings;

    // Asking at launch, before the user knows what the app is for, is how an
    // app gets a permanent no. The prompt comes later, from requestPermission.
    test('does not request any permission during setup', () async {
      await service.initialise();

      final darwin = captured().iOS!;
      expect(darwin.requestAlertPermission, isFalse);
      expect(darwin.requestBadgePermission, isFalse);
      expect(darwin.requestSoundPermission, isFalse);
    });
  });

  group('requestPermission', () {
    /// Stubs the Darwin prompt on both [ios] and [macos] with one answer.
    ///
    /// Written out twice rather than looped: the two mocks' only common
    /// supertype is `Mock`, which declares no `requestPermissions`.
    void darwinAnswers(bool? granted) {
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => granted);
      when(
        () => macos.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => granted);
    }

    group('on iOS', () {
      setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

      test('asks for alert, badge and sound', () async {
        darwinAnswers(true);

        await service.requestPermission();

        verify(
          () => ios.requestPermissions(alert: true, badge: true, sound: true),
        ).called(1);
      });

      test('returns true when granted', () async {
        darwinAnswers(true);

        expect(await service.requestPermission(), isTrue);
      });

      test('returns false when refused', () async {
        darwinAnswers(false);

        expect(await service.requestPermission(), isFalse);
      });

      // The plugin returns null when the OS gives no answer. Treating that as
      // granted would have the app schedule reminders that never arrive.
      test('a null answer is not a grant', () async {
        darwinAnswers(null);

        expect(await service.requestPermission(), isFalse);
      });

      test('returns false when there is no implementation', () async {
        when(
          plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >,
        ).thenReturn(null);

        expect(await service.requestPermission(), isFalse);
      });
    });

    // Android 13 (API 33) made POST_NOTIFICATIONS a runtime permission. This
    // branch did not exist: the reminder was scheduled, the OS dropped it,
    // and nothing in the app could tell.
    group('on Android', () {
      setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

      test('asks the Android implementation, not the iOS one', () async {
        when(android.requestNotificationsPermission)
            .thenAnswer((_) async => true);

        expect(await service.requestPermission(), isTrue);

        verify(android.requestNotificationsPermission).called(1);
        verifyNever(
          () => ios.requestPermissions(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          ),
        );
      });

      test('returns false when refused', () async {
        when(android.requestNotificationsPermission)
            .thenAnswer((_) async => false);

        expect(await service.requestPermission(), isFalse);
      });

      test('a null answer is not a grant', () async {
        when(android.requestNotificationsPermission)
            .thenAnswer((_) async => null);

        expect(await service.requestPermission(), isFalse);
      });
    });

    group('on macOS', () {
      setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);

      test('asks the macOS implementation, not the iOS one', () async {
        darwinAnswers(true);

        expect(await service.requestPermission(), isTrue);

        verify(
          () => macos.requestPermissions(alert: true, badge: true, sound: true),
        ).called(1);
        verifyNever(
          () => ios.requestPermissions(
            alert: any(named: 'alert'),
            badge: any(named: 'badge'),
            sound: any(named: 'sound'),
          ),
        );
      });
    });

    // Nothing to prompt for, either because the OS has no prompt or because
    // the platform has no reminder to grant permission for.
    group('platforms with no prompt', () {
      test('Windows needs no runtime grant', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        expect(await service.requestPermission(), isTrue);
      });

      // Linux can show a notification now and cannot schedule one for later,
      // which is why the guard asks `supportsScheduling` rather than kIsWeb.
      test('Linux cannot schedule, so it is not asked', () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;

        expect(await service.requestPermission(), isFalse);
        verifyNever(android.requestNotificationsPermission);
      });
    });
  });
}
