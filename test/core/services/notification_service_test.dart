import 'package:fantastic/core/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
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

  group('isPermissionGranted', () {
    /// A Darwin answer with [isEnabled] set and every other flag off.
    ///
    /// Only `isEnabled` is read, and the rest are set to the opposite value
    /// so a implementation that reached for `isAlertEnabled` — or for the
    /// record's truthiness — fails here rather than passing by coincidence.
    NotificationsEnabledOptions darwin({required bool isEnabled}) =>
        NotificationsEnabledOptions(
          isEnabled: isEnabled,
          isSoundEnabled: !isEnabled,
          isAlertEnabled: !isEnabled,
          isBadgeEnabled: !isEnabled,
          isProvisionalEnabled: !isEnabled,
          isCriticalEnabled: !isEnabled,
          isProvidesAppNotificationSettingsEnabled: !isEnabled,
        );

    // `kIsWeb` is a `const false` on the VM, so the web branch cannot be
    // reached from a test at all — the same limitation the `initialise`
    // group records. Linux is the platform that proves the gate is
    // `supportsScheduling` and not `kIsWeb`.
    test('returns false on Linux without touching the plugin', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;

      expect(await service.isPermissionGranted(), isFalse);
      verifyNever(
        plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >,
      );
    });

    test('returns true when iOS reports the permission enabled', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(ios.checkPermissions)
          .thenAnswer((_) async => darwin(isEnabled: true));

      expect(await service.isPermissionGranted(), isTrue);
    });

    test('returns false when iOS reports the permission disabled', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(ios.checkPermissions)
          .thenAnswer((_) async => darwin(isEnabled: false));

      expect(await service.isPermissionGranted(), isFalse);
    });

    test('reads macOS through its own implementation', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      when(macos.checkPermissions)
          .thenAnswer((_) async => darwin(isEnabled: true));

      expect(await service.isPermissionGranted(), isTrue);
      verifyNever(ios.checkPermissions);
    });

    test(
      'returns false when the iOS implementation resolves to null',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(
          plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >,
        ).thenReturn(null);

        expect(await service.isPermissionGranted(), isFalse);
      },
    );

    // The OS declining to answer is not a grant. Distinct from the case
    // above: there the plugin had no implementation to ask, here it asked
    // and got nothing back.
    test('returns false when the OS answer is null', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(ios.checkPermissions).thenAnswer((_) async => null);

      expect(await service.isPermissionGranted(), isFalse);
    });

    test('returns false when Android reports a null channel state', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      when(android.areNotificationsEnabled).thenAnswer((_) async => null);

      expect(await service.isPermissionGranted(), isFalse);
    });

    // `areNotificationsEnabled` and `requestNotificationsPermission` answer
    // different questions: a user can grant POST_NOTIFICATIONS and then turn
    // the channel off in system settings. Stubbing them to opposite values
    // is what catches an implementation that reused the request.
    test('reads the Android channel state, not the request result', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      when(android.areNotificationsEnabled).thenAnswer((_) async => false);
      when(android.requestNotificationsPermission)
          .thenAnswer((_) async => true);

      expect(await service.isPermissionGranted(), isFalse);
      verifyNever(android.requestNotificationsPermission);
    });

    test('returns true on Windows, which has no runtime permission', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      expect(await service.isPermissionGranted(), isTrue);
    });

    // The whole reason this method exists rather than reusing
    // `requestPermission`: iOS shows its dialog at most once per install, so
    // a query that prompts spends it.
    test('never calls requestPermissions', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      when(ios.checkPermissions)
          .thenAnswer((_) async => darwin(isEnabled: true));

      await service.isPermissionGranted();

      verifyNever(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      );
    });

    // Deliberately not caught and flattened to `false`: an unreachable
    // channel means the answer is unknown, and `false` is the specific claim
    // that notifications are off. A failed read and a real negative must not
    // look alike.
    test('lets a platform-channel failure propagate', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      when(android.areNotificationsEnabled)
          .thenThrow(PlatformException(code: 'channel-error'));

      expect(service.isPermissionGranted(), throwsA(isA<PlatformException>()));
    });
  });
}
