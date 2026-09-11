import 'dart:async';

import 'package:fantastic/core/constants/profile_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/core/providers/notification_providers.dart';
import 'package:fantastic/core/services/notification_service.dart';
import 'package:fantastic/features/profile/application/providers/profile_providers.dart';
import 'package:fantastic/features/profile/presentation/widgets/notification_setting_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../helpers/pump_app.dart';

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  late _MockNotificationService service;

  setUp(() {
    service = _MockNotificationService();
    when(service.requestPermission).thenAnswer((_) async => true);
  });

  // `flutter test` reports `defaultTargetPlatform` as android regardless of
  // the host, so `supportsScheduling` is true by default here and the
  // unsupported branch has to be asked for explicitly.
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Future<void> pumpTile(
    WidgetTester tester, {
    bool? granted,
    Object? permissionError,
  }) => pumpApp(
    tester,
    const NotificationSettingTile(),
    overrides: <Override>[
      notificationServiceProvider.overrideWithValue(service),
      notificationPermissionProvider.overrideWith((ref) async {
        if (permissionError != null) throw permissionError;
        return granted!;
      }),
    ],
  );

  testWidgets('shows the enabled state when permission is granted', (
    tester,
  ) async {
    await pumpTile(tester, granted: true);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_granted')), findsOneWidget);
    expect(find.text(ProfileCopy.notificationsOn), findsOneWidget);
    expect(find.byKey(const Key('enable_notifications_button')), findsNothing);
  });

  testWidgets('shows an enable action when permission is not granted', (
    tester,
  ) async {
    await pumpTile(tester, granted: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_denied')), findsOneWidget);
    expect(find.text(ProfileCopy.notificationsOffBody), findsOneWidget);
    expect(
      find.byKey(const Key('enable_notifications_button')),
      findsOneWidget,
    );
  });

  testWidgets('tapping enable requests permission and refreshes the state', (
    tester,
  ) async {
    var calls = 0;
    await pumpApp(
      tester,
      const NotificationSettingTile(),
      overrides: <Override>[
        notificationServiceProvider.overrideWithValue(service),
        // Denied on the first read, granted on the second: the row must show
        // the new answer without a tab switch, which only happens if the
        // provider is actually invalidated.
        notificationPermissionProvider.overrideWith((ref) async {
          calls++;
          return calls > 1;
        }),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('enable_notifications_button')));
    await tester.pumpAndSettle();

    verify(service.requestPermission).called(1);
    expect(find.byKey(const Key('notifications_granted')), findsOneWidget);
  });

  // A platform that cannot schedule is a third state, not "off": offering an
  // enable button on web or Linux would show a control that cannot work.
  testWidgets('shows the unsupported state on a platform that cannot '
      'schedule', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;

    await pumpTile(tester, granted: false);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_unsupported')), findsOneWidget);
    expect(find.byKey(const Key('enable_notifications_button')), findsNothing);
    expect(find.text(ProfileCopy.notificationsUnsupportedBody), findsOneWidget);

    // Cleared inside the body, not in `tearDown`: `testWidgets` asserts every
    // foundation debug variable is unset when the body returns, which runs
    // before any tear-down does.
    debugDefaultTargetPlatformOverride = null;
  });

  // A refusal is not an error — `OnboardingService` already treats it that
  // way. iOS spends its one prompt on the first ask, so a second tap cannot
  // re-ask and the row has to say where the setting now lives.
  testWidgets('a refused request leaves the row explained, not broken', (
    tester,
  ) async {
    when(service.requestPermission).thenAnswer((_) async => false);

    await pumpTile(tester, granted: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enable_notifications_button')));
    await tester.pumpAndSettle();

    expect(find.text(ProfileCopy.notificationsRefused), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Still tappable: the button is not left disabled by a refusal.
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('enable_notifications_button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  // The busy flag is cleared in a `finally`, not after the await — clearing
  // it after awaiting is the gotcha `design/m6_handoff.md` records, and a
  // throwing platform channel would otherwise disable the button for good.
  testWidgets('a throwing request is reported on the row, not thrown', (
    tester,
  ) async {
    // A completer rather than `thenThrow`, so the error lands at an instant
    // this test chooses: a synchronous throw out of the mock is reported to
    // the binding before the tap returns and cannot be drained in order.
    final request = Completer<bool>();
    when(service.requestPermission).thenAnswer((_) => request.future);

    await pumpTile(tester, granted: false);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enable_notifications_button')));
    await tester.pump();

    // Busy: the button is disabled while the request is in flight, so a
    // second tap cannot stack a second prompt.
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('enable_notifications_button')),
          )
          .onPressed,
      isNull,
    );

    request.completeError(
      const PersistenceException('channel gone', 'platform'),
    );
    await tester.pumpAndSettle();

    // Reported on the row, not thrown into the zone: an unhandled error out
    // of a tap handler takes the frame down and tells the user nothing.
    expect(tester.takeException(), isNull);
    expect(find.text(ProfileCopy.notificationsCheckFailed), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.byKey(const Key('enable_notifications_button')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('says it cannot tell when the permission check fails', (
    tester,
  ) async {
    await pumpTile(
      tester,
      permissionError: const PersistenceException('no channel', 'platform'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('notifications_unknown')), findsOneWidget);
    expect(find.text(ProfileCopy.notificationsCheckFailed), findsOneWidget);
  });

  testWidgets('settles while the permission check is still in flight', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const NotificationSettingTile(),
      overrides: <Override>[
        notificationServiceProvider.overrideWithValue(service),
        notificationPermissionProvider.overrideWith(
          (ref) => Completer<bool>().future,
        ),
      ],
    );

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('keeps a 44pt minimum touch target', (tester) async {
    await pumpTile(tester, granted: false);
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('notifications_denied'))).height,
      greaterThanOrEqualTo(NotificationSettingTile.minTouchTarget),
    );
  });
}
