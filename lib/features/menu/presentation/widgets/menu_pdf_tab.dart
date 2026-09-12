import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/document_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/file_selector_document_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `קובץ PDF` — picks a PDF menu and hands its path to [onAnalyse].
///
/// The sibling [MenuPagesTab] establishes: this widget only collects and
/// displays the chosen input, and knows nothing about `PdfPageExtractor`,
/// OCR, or the analyser. Reading the file, deciding which pages need
/// rasterising, and calling [MenuAnalyzer] all happen in
/// `MenuScannerScreen._analysePdf` — the same split `MenuPagesTab` keeps
/// from its own page-collection loop.
///
/// **Deliberately not gated on OCR availability.** A text-layer PDF needs no
/// OCR at all — that check belongs to `MenuScannerScreen`, and only once it
/// knows whether the chosen PDF actually has a page with no text layer. This
/// widget would be wrong to block every PDF behind an engine most of them
/// never need.
///
/// ## The states, in the order they are checked
///
/// 1. **Nothing chosen** — [pickPdfButton], plus a line naming the
///    photographed-pages mode as the alternative.
/// 2. **Chosen** — the file's name (never its full path: a path is noise
///    and can leak a username into a screenshot), a way to clear it, and
///    `נתחו` enabled unless [analysing].
///
/// A third state — "reading" — is driven by the host screen, exactly as
/// [MenuPagesTab]'s OCR progress is: this widget renders nothing itself
/// while [analysing] is true beyond disabling its own controls.
class MenuPdfTab extends ConsumerStatefulWidget {
  const MenuPdfTab({
    required this.onAnalyse,
    required this.analysing,
    super.key,
  });

  /// Called with the chosen PDF's path when the user taps `נתחו`.
  final ValueChanged<String> onAnalyse;

  /// Whether the host screen is mid-analysis. Disables both the clear
  /// control and `נתחו` so a second tap cannot start an overlapping request.
  final bool analysing;

  @override
  ConsumerState<MenuPdfTab> createState() => _MenuPdfTabState();
}

class _MenuPdfTabState extends ConsumerState<MenuPdfTab> {
  String? _path;

  /// A picker failure — a one-line notice, never a thrown error. Mirrors
  /// `MenuPagesTab._notice`.
  String? _notice;

  Future<void> _pick() async {
    final String? path;
    try {
      path = await ref.read(documentPickerProvider).pickPdf();
    } on DocumentPickerException catch (_) {
      // Covers both a genuine platform failure and — since #408 —
      // `FileSelectorDocumentPicker`'s no-filesystem-path case (the web),
      // which used to return null here and read as nothing having
      // happened at all.
      if (mounted) {
        setState(() => _notice = MenuCopy.pdfPickError);
      }
      return;
    }

    // Null means the user backed out of the picker. Not an error, and
    // nothing changes — the single most common way this call ends.
    if (path == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _path = path;
        _notice = null;
      });
    }
  }

  void _clear() {
    if (widget.analysing) {
      return;
    }
    setState(() {
      _path = null;
      _notice = null;
    });
  }

  void _submit() {
    final path = _path;
    if (path == null || widget.analysing) {
      return;
    }
    widget.onAnalyse(path);
  }

  @override
  Widget build(BuildContext context) {
    final path = _path;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: path == null
            ? _buildEmpty(context)
            : _buildChosen(context, path),
      ),
    );
  }

  List<Widget> _buildEmpty(BuildContext context) => [
    const Icon(Icons.picture_as_pdf_outlined, size: 40, color: AppTheme.accent),
    const SizedBox(height: 12),
    Center(
      child: OutlinedButton.icon(
        key: const Key('menu_pdf_pick_button'),
        onPressed: _pick,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text(MenuCopy.pickPdfButton),
      ),
    ),
    const SizedBox(height: 12),
    Text(
      MenuCopy.pdfAlternativeHint,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    ),
    if (_notice != null) ...[
      const SizedBox(height: 8),
      Text(
        _notice!,
        key: const Key('menu_pdf_notice'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  ];

  List<Widget> _buildChosen(BuildContext context, String path) => [
    Row(
      children: [
        const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _fileNameOf(path),
            key: const Key('menu_pdf_filename'),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          key: const Key('menu_pdf_clear'),
          tooltip: MenuCopy.removePdfTooltip,
          icon: const Icon(Icons.close),
          onPressed: widget.analysing ? null : _clear,
        ),
      ],
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('menu_analyse_pdf_button'),
      onPressed: widget.analysing ? null : _submit,
      child: const Text(MenuCopy.analyseButton),
    ),
  ];

  /// The last path segment of [path], on either separator — `file_selector`
  /// hands back a native path, `\` on Windows and `/` everywhere else this
  /// app has ever run.
  ///
  /// Not `dart:io`'s `File` or `package:path`: this widget ships in the web
  /// bundle, and plain string handling is the same choice
  /// `_PageThumbnail` in `menu_pages_tab.dart` makes for the same reason.
  static String _fileNameOf(String path) {
    final normalised = path.replaceAll(r'\', '/');
    final lastSlash = normalised.lastIndexOf('/');
    return lastSlash == -1 ? normalised : normalised.substring(lastSlash + 1);
  }
}
