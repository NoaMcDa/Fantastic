import 'dart:async';
import 'dart:typed_data';

import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_controller_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/camera_session.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/image_picker_photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/photo_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/screens/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `XFile` is re-exported by `image_picker`, which is a direct dependency;
// `cross_file` itself is only transitive, and importing it directly would be
// the implicit dependency `depend_on_referenced_packages` exists to catch.
// The same justification `photo_bytes_reader.dart` (#320) carries.
import 'package:image_picker/image_picker.dart';

/// `צלמו עמודים` — captures or imports up to [MenuVerdictRules.maxPages]
/// menu pages and hands their paths to [onAnalyse].
///
/// Feeds the same [MenuAnalyzer.analyse] call the pasted-text mode does — no
/// second pipeline, only a page-collection loop over two interfaces that
/// already exist: [CameraSession] (M6) and [PhotoPicker] (#354).
///
/// ## The states, in the order they are checked
///
/// The same discipline [CameraScreen] documents, and for the same reason:
/// this widget is almost entirely loading and error states.
///
/// 1. **OCR unavailable** — checked before a camera is ever opened. There is
///    no point asking for a camera permission to feed pages to an analyser
///    that cannot read them; the way out is `הדביקו את הטקסט במקום`.
/// 2. **Camera problem** — refused, refused permanently, no camera, or a
///    platform failure. The gallery stays offered here: a menu photographed
///    earlier is a real case, and it does not need a live camera.
/// 3. **Starting** — a labelled indicator, never a bare spinner.
/// 4. **Ready** — the viewfinder, torch, shutter and gallery, the thumbnail
///    strip, the page counter, and `נתחו`.
///
/// ## Why the camera never keeps running off-screen
///
/// `MenuScannerScreen` mounts this widget only while its photo tab is
/// selected — switching to `הדביקו טקסט` removes it from the tree entirely,
/// which disposes it and, through [dispose], stops the session. Selecting
/// `צלמו עמודים` again creates a fresh instance, which opens a fresh camera.
/// That is the "stopped when not visible, restarted on return" discipline
/// the issue asks for — it costs no extra code because plain widget
/// unmounting already provides it.
class MenuPagesTab extends ConsumerStatefulWidget {
  const MenuPagesTab({
    required this.onAnalyse,
    required this.onSwitchToTextMode,
    required this.analysing,
    super.key,
  });

  /// Called with the collected paths, in capture/pick order, when the user
  /// taps `נתחו`.
  final ValueChanged<List<String>> onAnalyse;

  /// Switches the mode selector back to `הדביקו טקסט`. Reached from the
  /// OCR-unavailable state's link, so a build with no engine still has a
  /// working path through this screen.
  final VoidCallback onSwitchToTextMode;

  /// Whether the host screen is mid-analysis. Disables `נתחו` so a second
  /// tap cannot start an overlapping request while thumbnails stay visible
  /// and untouched.
  final bool analysing;

  @override
  ConsumerState<MenuPagesTab> createState() => _MenuPagesTabState();
}

class _MenuPagesTabState extends ConsumerState<MenuPagesTab> {
  CameraSession? _session;
  CameraProblem? _problem;
  bool _ocrUnavailable = false;
  bool _starting = true;
  bool _torchOn = false;

  final List<String> _pages = [];

  /// A cap or a picker failure — a one-line notice, never a thrown error and
  /// never something that discards a page already collected.
  String? _notice;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    // Holding the session in a local first, the same discipline
    // `CameraScreen.dispose` documents: the field is already null if
    // anything re-enters while `stop()` is in flight.
    final session = _session;
    _session = null;
    unawaited(session?.stop());
    super.dispose();
  }

  Future<void> _start() async {
    if (!ref.read(textRecognitionServiceProvider).isAvailable) {
      setState(() {
        _ocrUnavailable = true;
        _starting = false;
      });
      return;
    }

    final session = ref.read(cameraSessionBuilderProvider)();
    try {
      await session.start();
    } on CameraSessionException catch (error) {
      if (mounted) {
        setState(() {
          _problem = error.problem;
          _starting = false;
        });
      }
      return;
    } on Object {
      if (mounted) {
        setState(() {
          _problem = CameraProblem.failed;
          _starting = false;
        });
      }
      return;
    }

    if (!mounted) {
      // Left while the camera was opening. Release it rather than leaking a
      // live camera for the life of the app.
      await session.stop();
      return;
    }
    setState(() {
      _session = session;
      _starting = false;
    });
  }

  Future<void> _retry() async {
    final previous = _session;
    _session = null;
    unawaited(previous?.stop());
    setState(() {
      _problem = null;
      _starting = true;
    });
    await _start();
  }

  Future<void> _toggleTorch() async {
    final session = _session;
    if (session == null) {
      return;
    }
    final wanted = !_torchOn;
    try {
      await session.setTorch(on: wanted);
    } on Object {
      // A device with no torch, or one that refuses. Not worth a notice; the
      // button simply does not latch — the same choice `CameraScreen` makes.
      return;
    }
    if (mounted) {
      setState(() => _torchOn = wanted);
    }
  }

  Future<void> _capture() async {
    final session = _session;
    if (session == null || _pages.length >= MenuVerdictRules.maxPages) {
      return;
    }

    final String path;
    try {
      path = await session.capturePhoto();
    } on CameraSessionException catch (_) {
      if (mounted) {
        setState(() => _notice = MenuCopy.captureFailed);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _pages.add(path);
        _notice = null;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final remaining = MenuVerdictRules.maxPages - _pages.length;
    if (remaining <= 0) {
      setState(
        () => _notice = MenuCopy.pageCapNotice(MenuVerdictRules.maxPages),
      );
      return;
    }

    final List<String> picked;
    try {
      picked = await ref
          .read(photoPickerProvider)
          .pickMultiple(limit: remaining);
    } on PhotoPickerException catch (_) {
      if (mounted) {
        setState(() => _notice = MenuCopy.galleryError);
      }
      return;
    }

    // Empty is the user backing out of the picker. Not an error, and
    // nothing changes.
    if (picked.isEmpty) {
      return;
    }

    // `image_picker`'s own `limit` is not honoured on every platform
    // (`design/m16_menu_scanner_research.md` §4.2), so the cap is enforced
    // again here, in Dart, on whatever the picker actually returned.
    final overflowed = picked.length > remaining;
    final accepted = picked.take(remaining).toList();

    if (mounted) {
      setState(() {
        _pages.addAll(accepted);
        _notice = overflowed
            ? MenuCopy.pageCapNotice(MenuVerdictRules.maxPages)
            : null;
      });
    }
  }

  void _removePage(int index) {
    setState(() => _pages.removeAt(index));
  }

  void _submit() {
    if (_pages.isEmpty || widget.analysing) {
      return;
    }
    widget.onAnalyse(List<String>.unmodifiable(_pages));
  }

  @override
  Widget build(BuildContext context) {
    if (_ocrUnavailable) {
      return _buildOcrUnavailable(context);
    }
    if (_problem != null) {
      return _buildProblem(context, _problem!);
    }
    if (_starting || _session == null) {
      return const _StartingIndicator();
    }
    return _buildReady(context);
  }

  Widget _buildOcrUnavailable(BuildContext context) => Padding(
    key: const Key('menu_pages_unavailable'),
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(
          Icons.no_photography_outlined,
          size: 40,
          color: AppTheme.accent,
        ),
        const SizedBox(height: 12),
        Text(
          // `@visibleForTesting` on `CameraScreen.unavailableAdvice` marks it
          // test-only for *its own* screen; the issue's explicit instruction
          // is to reuse this exact copy rather than write a second switch
          // over `defaultTargetPlatform` here. `lib/features/keto_lens/` is
          // read-only for this issue, so the annotation cannot be relaxed —
          // this is the one line the reuse is worth the ignore.
          // ignore: invalid_use_of_visible_for_testing_member
          CameraScreen.unavailableAdvice(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        TextButton(
          key: const Key('menu_switch_to_text_button'),
          onPressed: widget.onSwitchToTextMode,
          child: const Text(MenuCopy.switchToTextMode),
        ),
      ],
    ),
  );

  Widget _buildProblem(BuildContext context, CameraProblem problem) => Padding(
    key: const Key('menu_camera_problem'),
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.videocam_off_outlined,
          size: 40,
          color: AppTheme.accent,
        ),
        const SizedBox(height: 12),
        Text(
          // Same reuse, same reason as `unavailableAdvice` above.
          // ignore: invalid_use_of_visible_for_testing_member
          CameraScreen.problemTitle(problem),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          // ignore: invalid_use_of_visible_for_testing_member
          CameraScreen.problemAdvice(problem),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (problem != CameraProblem.permissionDeniedPermanently) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              key: const Key('menu_camera_retry_button'),
              onPressed: _retry,
              child: const Text(AddMealCopy.retry),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            key: const Key('menu_gallery_button'),
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text(MenuCopy.importFromGallery),
          ),
        ),
        const SizedBox(height: 16),
        _PagesArea(
          pages: _pages,
          notice: _notice,
          analysing: widget.analysing,
          onRemove: _removePage,
          onSubmit: _submit,
        ),
      ],
    ),
  );

  Widget _buildReady(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 260,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _session!.buildPreview(),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  key: const Key('menu_torch_button'),
                  icon: Icon(
                    _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                    color: Colors.white,
                  ),
                  onPressed: _toggleTorch,
                ),
              ),
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('menu_gallery_button'),
                        tooltip: MenuCopy.importFromGallery,
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.white,
                        ),
                        onPressed: _pickFromGallery,
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        key: const Key('menu_capture_button'),
                        iconSize: 48,
                        icon: const Icon(Icons.camera, color: Colors.white),
                        onPressed: _pages.length >= MenuVerdictRules.maxPages
                            ? null
                            : _capture,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _PagesArea(
        pages: _pages,
        notice: _notice,
        analysing: widget.analysing,
        onRemove: _removePage,
        onSubmit: _submit,
      ),
    ],
  );
}

/// The camera-starting state.
///
/// Deliberately **not** a `CircularProgressIndicator` — the same choice
/// `CameraScreen`'s own starting state makes and documents: an indeterminate
/// animation never lets `pumpAndSettle` return, and opening a camera is
/// sub-second anyway, so a static icon and a label are the whole state.
class _StartingIndicator extends StatelessWidget {
  const _StartingIndicator();

  @override
  Widget build(BuildContext context) => const Padding(
    key: Key('menu_camera_starting'),
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_camera_outlined, size: 40, color: AppTheme.accent),
          SizedBox(height: 12),
          Text(MenuCopy.cameraStartingLabel),
        ],
      ),
    ),
  );
}

/// The thumbnail strip, the notice, the page counter and `נתחו` — shared
/// between the ready state (below the viewfinder) and the camera-problem
/// state (below the gallery-only fallback), so a page picked from either
/// place lands in the identical list and is submitted the identical way.
class _PagesArea extends StatelessWidget {
  const _PagesArea({
    required this.pages,
    required this.notice,
    required this.analysing,
    required this.onRemove,
    required this.onSubmit,
  });

  final List<String> pages;
  final String? notice;
  final bool analysing;
  final ValueChanged<int> onRemove;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (notice != null) ...[
        Text(
          notice!,
          key: const Key('menu_page_notice'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
      ],
      if (pages.isNotEmpty) ...[
        SizedBox(
          height: 96,
          child: ListView.builder(
            // A horizontal list already starts on the right under the app's
            // RTL `Directionality` — `design/m2_handoff.md`'s trap is a
            // *drag* direction, not a build-order one, so no `reverse` is
            // needed here.
            scrollDirection: Axis.horizontal,
            itemCount: pages.length,
            itemBuilder: (context, index) => _PageThumbnail(
              index: index,
              path: pages[index],
              onRemove: () => onRemove(index),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          MenuCopy.pageCounterLabel(pages.length, MenuVerdictRules.maxPages),
          key: const Key('menu_page_counter'),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(
        key: const Key('menu_analyse_pages_button'),
        onPressed: pages.isNotEmpty && !analysing ? onSubmit : null,
        child: const Text(MenuCopy.analyseButton),
      ),
    ],
  );
}

/// One captured or imported page, with a remove control.
///
/// Reads its bytes through `XFile` rather than `dart:io`'s `File` — this
/// widget ships in the web bundle, and M6 established that a `File` import
/// there analyses and builds clean, then throws at run time in a browser
/// only. The same technique `photo_bytes_reader.dart` (#320) uses.
class _PageThumbnail extends StatelessWidget {
  const _PageThumbnail({
    required this.index,
    required this.path,
    required this.onRemove,
  });

  final int index;
  final String path;
  final VoidCallback onRemove;

  static Future<Uint8List?> _readBytes(String path) async {
    try {
      return await XFile(path).readAsBytes();
    } on Object catch (_) {
      // `Object`, not `Exception`: a missing file throws a
      // `FileSystemException` on the VM but a bad blob URL surfaces as an
      // `Error` in the browser — the same reasoning `XFilePhotoBytesReader`
      // carries.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: 8),
    child: Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            key: Key('menu_page_thumb_$index'),
            width: 72,
            height: 96,
            child: FutureBuilder<Uint8List?>(
              future: _readBytes(path),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) {
                  return ColoredBox(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    child: const Icon(Icons.image_outlined),
                  );
                }
                return Image.memory(bytes, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        PositionedDirectional(
          top: 0,
          end: 0,
          child: IconButton(
            key: Key('menu_page_remove_$index'),
            tooltip: MenuCopy.removePageTooltip,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20,
            icon: const Icon(Icons.cancel, color: Colors.white),
            onPressed: onRemove,
          ),
        ),
      ],
    ),
  );
}
