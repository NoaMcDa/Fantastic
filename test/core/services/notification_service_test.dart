import 'package:fantastic/core/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

class _MockIOSPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

void main() {
  late _MockPlugin plugin;
  late _MockIOSPlugin ios;
  late NotificationService service;

  setUpAll(() => registerFallbackValue(const InitializationSettings()));

  setUp(() {
    plugin = _MockPlugin();
    ios = _MockIOSPlugin();
    service = NotificationService(plugin);
    when(() => plugin.initialize(settings: any(named: 'settings')))
        .thenAnswer((_) async => true);
    when(
      plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >,
    ).thenReturn(ios);
  });

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
    test('asks for alert, badge and sound', () async {
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => true);

      await service.requestPermission();

      verify(
        () => ios.requestPermissions(alert: true, badge: true, sound: true),
      ).called(1);
    });

    test('returns true when granted', () async {
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => true);

      expect(await service.requestPermission(), isTrue);
    });

    test('returns false when refused', () async {
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => false);

      expect(await service.requestPermission(), isFalse);
    });

    // The plugin returns null when the OS gives no answer. Treating that as
    // granted would have the app schedule reminders that never arrive.
    test('a null answer is not a grant', () async {
      when(
        () => ios.requestPermissions(
          alert: any(named: 'alert'),
          badge: any(named: 'badge'),
          sound: any(named: 'sound'),
        ),
      ).thenAnswer((_) async => null);

      expect(await service.requestPermission(), isFalse);
    });

    // On a platform with no iOS implementation to resolve.
    test('returns false when there is no platform implementation', () async {
      when(
        plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >,
      ).thenReturn(null);

      expect(await service.requestPermission(), isFalse);
    });
  });
}
