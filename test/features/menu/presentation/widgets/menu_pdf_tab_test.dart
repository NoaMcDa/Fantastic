import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/document_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/file_selector_document_picker.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_pdf_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

/// A [DocumentPicker] that is whatever the test needs it to be — the same
/// hand-rolled-fake technique `camera_screen_test.dart` established and
/// `menu_pages_tab_test.dart` reuses for its own gallery fake.
class _FakePicker implements DocumentPicker {
  String? path;
  DocumentPickerException? error;
  int calls = 0;

  @override
  Future<String?> pickPdf() async {
    calls++;
    if (error != null) {
      throw error!;
    }
    return path;
  }
}

void main() {
  late _FakePicker picker;
  late List<String> analysed;

  setUp(() {
    picker = _FakePicker();
    analysed = [];
  });

  Future<void> pumpTab(WidgetTester tester, {bool analysing = false}) async {
    await pumpApp(
      tester,
      MenuPdfTab(onAnalyse: analysed.add, analysing: analysing),
      overrides: [documentPickerProvider.overrideWithValue(picker)],
    );
    await tester.pumpAndSettle();
  }

  group('nothing chosen', () {
    testWidgets('shows the pick button and the photo-mode alternative', (
      tester,
    ) async {
      await pumpTab(tester);

      expect(find.byKey(const Key('menu_pdf_pick_button')), findsOneWidget);
      expect(find.text(MenuCopy.pdfAlternativeHint), findsOneWidget);
      expect(find.byKey(const Key('menu_pdf_filename')), findsNothing);
      expect(find.byKey(const Key('menu_analyse_pdf_button')), findsNothing);
    });

    testWidgets('a cancelled pick (null) leaves the tab unchanged, no notice', (
      tester,
    ) async {
      picker.path = null;
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_pdf_pick_button')));
      await tester.pumpAndSettle();

      expect(picker.calls, 1);
      expect(find.byKey(const Key('menu_pdf_filename')), findsNothing);
      expect(find.byKey(const Key('menu_pdf_notice')), findsNothing);
    });

    testWidgets('a DocumentPickerException — a platform failure, or the web '
        'no-path case — shows a notice rather than doing nothing', (
      tester,
    ) async {
      picker.error = const DocumentPickerException('dialog denied');
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_pdf_pick_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_pdf_notice')), findsOneWidget);
      expect(find.text(MenuCopy.pdfPickError), findsOneWidget);
      expect(find.byKey(const Key('menu_pdf_filename')), findsNothing);
    });
  });

  group('chosen', () {
    testWidgets('shows only the file name, not the full path', (tester) async {
      picker.path = '/home/noa/downloads/menu.pdf';
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_pdf_pick_button')));
      await tester.pumpAndSettle();

      expect(find.text('menu.pdf'), findsOneWidget);
      expect(find.textContaining('/home/noa'), findsNothing);
      expect(find.byKey(const Key('menu_analyse_pdf_button')), findsOneWidget);
    });

    testWidgets('strips a Windows-style path to its file name too', (
      tester,
    ) async {
      picker.path = r'C:\Users\noa\menu.pdf';
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_pdf_pick_button')));
      await tester.pumpAndSettle();

      expect(find.text('menu.pdf'), findsOneWidget);
    });

    testWidgets('נתחו calls onAnalyse with the chosen path', (tester) async {
      picker.path = '/tmp/menu.pdf';
      await pumpTab(tester);

      await tester.tap(find.byKey(const Key('menu_pdf_pick_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('menu_analyse_pdf_button')));
      await tester.pumpAndSettle();

      expect(analysed, ['/tmp/menu.pdf']);
    });

    testWidgets('clearing returns to the empty state and hides נתחו', (
      tester,
    ) async {
      picker.path = '/tmp/menu.pdf';
      await pumpTab(tester);
      await tester.tap(find.byKey(const Key('menu_pdf_pick_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('menu_pdf_clear')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('menu_pdf_filename')), findsNothing);
      expect(find.byKey(const Key('menu_analyse_pdf_button')), findsNothing);
      expect(find.byKey(const Key('menu_pdf_pick_button')), findsOneWidget);
    });

    testWidgets('analysing disables נתחו and the clear control', (
      tester,
    ) async {
      picker.path = '/tmp/menu.pdf';
      await pumpTab(tester, analysing: true);
      await tester.tap(find.byKey(const Key('menu_pdf_pick_button')));
      await tester.pumpAndSettle();

      final analyseButton = tester.widget<FilledButton>(
        find.byKey(const Key('menu_analyse_pdf_button')),
      );
      expect(analyseButton.onPressed, isNull);

      final clearButton = tester.widget<IconButton>(
        find.byKey(const Key('menu_pdf_clear')),
      );
      expect(clearButton.onPressed, isNull);
    });
  });
}
