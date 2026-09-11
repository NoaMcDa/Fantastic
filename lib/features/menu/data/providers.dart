/// Menu-scanner wiring.
///
/// Follows `CLAUDE.md`'s provider rule: repository/service wiring lives in
/// each feature's `data/providers.dart`, never in `application/`, so a
/// generated file that no test imports never lands inside the coverage gate
/// declaration-only files sit behind. `MenuPageReader` itself stays in
/// `application/` — only its wiring is here. #361 appends
/// `menuAnalyzerProvider` to this same file in a later wave.
library;

import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/menu/application/menu_page_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The on-device menu-page OCR loop.
///
/// Not `keepAlive`: unlike the stateless Keto Lens wiring it wraps, this
/// holds no compiled state worth keeping between scans, and a fresh instance
/// per listener costs nothing but a field assignment.
@riverpod
MenuPageReader menuPageReader(Ref ref) =>
    MenuPageReader(recognizer: ref.watch(textRecognitionServiceProvider));
