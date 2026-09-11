import 'dart:async';

import 'package:fantastic/core/constants/profile_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';
import 'package:fantastic/features/profile/presentation/widgets/estimation_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../helpers/pump_app.dart';

class _MockRepository extends Mock implements EstimationSettingsRepository {}

void main() {
  late _MockRepository repository;

  setUpAll(() => registerFallbackValue(const EstimationSettings()));

  setUp(() {
    repository = _MockRepository();
    when(() => repository.save(any())).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments.single as EstimationSettings,
    );
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    EstimationSettings stored = const EstimationSettings(),
    Object? loadError,
    bool loadHangs = false,
  }) async {
    if (loadHangs) {
      when(repository.load)
          .thenAnswer((_) => Completer<EstimationSettings>().future);
    } else if (loadError != null) {
      when(repository.load).thenThrow(loadError);
    } else {
      when(repository.load).thenAnswer((_) async => stored);
    }

    await pumpApp(
      tester,
      const SingleChildScrollView(child: EstimationSettingsSection()),
      overrides: <Override>[
        estimationSettingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    if (!loadHangs) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// The settings the section last handed the repository.
  ///
  /// Called once per test: mocktail marks a call verified, so a second
  /// `verify` in the same test matches nothing.
  EstimationSettings saved() =>
      verify(() => repository.save(captureAny())).captured.last
          as EstimationSettings;

  String stateLine(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('estimation_state_line'))).data!;

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('estimation_save_button')));
    await tester.tap(find.byKey(const Key('estimation_save_button')));
    await tester.pumpAndSettle();
  }

  group('saving', () {
    testWidgets('a key and consent are saved together', (tester) async {
      await pumpSection(tester);

      await tester.enterText(
        find.byKey(const Key('estimation_api_key_field')),
        'sk-or-v1-abcdef',
      );
      await tester.tap(find.byKey(const Key('estimation_consent_checkbox')));
      await tester.pumpAndSettle();
      await tapSave(tester);

      final settings = saved();
      expect(settings.apiKey, 'sk-or-v1-abcdef');
      expect(settings.consentAccepted, isTrue);
    });

    testWidgets('the state line reads active once both halves are stored', (
      tester,
    ) async {
      await pumpSection(
        tester,
        stored: const EstimationSettings(
          apiKey: 'sk-or-v1-abcdef',
          consentAccepted: true,
        ),
      );

      expect(stateLine(tester), ProfileCopy.estimationOn);
    });

    testWidgets('a whitespace-only key is not accepted as a key', (
      tester,
    ) async {
      await pumpSection(tester);

      await tester.enterText(
        find.byKey(const Key('estimation_api_key_field')),
        '    ',
      );
      await tapSave(tester);

      expect(saved().apiKey, isNull);
    });

    // A user who only wanted to tick the box must not lose their key to it.
    // Clearing has its own button.
    testWidgets('an empty field leaves a stored key alone', (tester) async {
      await pumpSection(
        tester,
        stored: const EstimationSettings(apiKey: 'sk-or-v1-keepme'),
      );

      await tester.tap(find.byKey(const Key('estimation_consent_checkbox')));
      await tester.pumpAndSettle();
      await tapSave(tester);

      final settings = saved();
      expect(settings.apiKey, 'sk-or-v1-keepme');
      expect(settings.consentAccepted, isTrue);
    });

    testWidgets('removing the key clears it and keeps consent', (tester) async {
      await pumpSection(
        tester,
        stored: const EstimationSettings(
          apiKey: 'sk-or-v1-abcdef',
          consentAccepted: true,
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('estimation_remove_key_button')),
      );
      await tester.tap(find.byKey(const Key('estimation_remove_key_button')));
      await tester.pumpAndSettle();

      final settings = saved();
      expect(settings.apiKey, isNull);
      expect(settings.consentAccepted, isTrue);
    });

    testWidgets('the remove button is absent when no key is stored', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(
        find.byKey(const Key('estimation_remove_key_button')),
        findsNothing,
      );
    });
  });

  group('the stored key is never shown', () {
    const key = 'sk-or-v1-SECRET-TAIL9876';

    testWidgets('the full key is nowhere in the widget tree', (tester) async {
      await pumpSection(tester, stored: const EstimationSettings(apiKey: key));

      // A settings screen is shoulder-surfable, and the field exists to
      // *replace* the key rather than to display it.
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(texts, isNot(contains(key)));
      expect(find.text(key), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('estimation_api_key_field')),
            )
            .controller
            ?.text,
        isEmpty,
      );
    });

    testWidgets('the placeholder describes it by its last four characters', (
      tester,
    ) async {
      await pumpSection(tester, stored: const EstimationSettings(apiKey: key));

      final field = tester.widget<TextField>(
        find.byKey(const Key('estimation_api_key_field')),
      );
      expect(field.decoration!.hintText, endsWith('9876'));
      expect(field.decoration!.hintText, isNot(contains('SECRET')));
    });

    testWidgets('there is no placeholder when nothing is stored', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('estimation_api_key_field')),
            )
            .decoration!
            .hintText,
        isNull,
      );
    });

    testWidgets('the field is obscured until the toggle is used', (
      tester,
    ) async {
      await pumpSection(tester);

      TextField field() => tester.widget<TextField>(
        find.byKey(const Key('estimation_api_key_field')),
      );
      expect(field().obscureText, isTrue);

      await tester.tap(find.byKey(const Key('estimation_key_visibility')));
      await tester.pumpAndSettle();

      expect(field().obscureText, isFalse);
    });
  });

  group('the state line names the missing half', () {
    // A user told only that estimation is off has no way to know which of
    // the two things to do.
    testWidgets('consent without a key', (tester) async {
      await pumpSection(
        tester,
        stored: const EstimationSettings(consentAccepted: true),
      );

      expect(stateLine(tester), ProfileCopy.estimationNoKey);
    });

    testWidgets('a key without consent', (tester) async {
      await pumpSection(
        tester,
        stored: const EstimationSettings(apiKey: 'sk-or-v1-abcdef'),
      );

      expect(stateLine(tester), ProfileCopy.estimationNoConsent);
    });

    testWidgets('neither', (tester) async {
      await pumpSection(tester);

      expect(stateLine(tester), ProfileCopy.estimationNoKeyOrConsent);
    });
  });

  group('consent', () {
    testWidgets('is unticked on a fresh install', (tester) async {
      await pumpSection(tester);

      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('estimation_consent_checkbox')),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('reflects a stored acceptance', (tester) async {
      await pumpSection(
        tester,
        stored: const EstimationSettings(consentAccepted: true),
      );

      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('estimation_consent_checkbox')),
            )
            .value,
        isTrue,
      );
    });
  });

  group('failure', () {
    // The defect that cost four milestones: in riverpod 3 a provider that
    // failed before producing a value is `AsyncLoading` *with* an error, so
    // an `isLoading`-first check shows a spinner forever.
    testWidgets('a failed load shows an error, not a spinner', (tester) async {
      await pumpSection(
        tester,
        loadError: const PersistenceException('load failed', 'store closed'),
      );

      expect(find.byKey(const Key('estimation_load_failed')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a failed load renders no consent checkbox to mislead with', (
      tester,
    ) async {
      await pumpSection(
        tester,
        loadError: const PersistenceException('load failed', 'store closed'),
      );

      // An unticked box here would invite the user to "fix" something that
      // is not broken.
      expect(
        find.byKey(const Key('estimation_consent_checkbox')),
        findsNothing,
      );
    });

    testWidgets('a failed save keeps the typed key and says so', (
      tester,
    ) async {
      await pumpSection(tester);
      when(() => repository.save(any()))
          .thenThrow(const PersistenceException('save failed', 'store closed'));

      await tester.enterText(
        find.byKey(const Key('estimation_api_key_field')),
        'sk-or-v1-typed',
      );
      await tapSave(tester);

      expect(find.byKey(const Key('estimation_save_failed')), findsOneWidget);
      // Emptying the field would say something was saved that was not.
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('estimation_api_key_field')),
            )
            .controller
            ?.text,
        'sk-or-v1-typed',
      );
    });

    testWidgets('a failed save re-enables the button', (tester) async {
      await pumpSection(tester);
      when(() => repository.save(any()))
          .thenThrow(const PersistenceException('save failed', 'store closed'));

      await tapSave(tester);

      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('estimation_save_button')),
            )
            .onPressed,
        isNotNull,
      );
    });

    // No forever-animation on a tab screen (#88).
    testWidgets('settles while the read is still in flight', (tester) async {
      await pumpSection(tester, loadHangs: true);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  testWidgets('the key source is selectable text, not a launcher', (
    tester,
  ) async {
    await pumpSection(tester);

    // M15 adds no plugin; a selectable URL works on all six targets.
    expect(find.byKey(const Key('estimation_key_source')), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('estimation_key_source')),
          )
          .data,
      ProfileCopy.estimationKeySource,
    );
  });

  testWidgets('the disclosure is always visible, not behind an expander', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text(ProfileCopy.estimationDisclosure), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('the consent row keeps a 44pt minimum touch target', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(
      tester
          .getSize(find.byKey(const Key('estimation_consent_checkbox')))
          .height,
      greaterThanOrEqualTo(EstimationSettingsSection.minTouchTarget),
    );
  });
}
