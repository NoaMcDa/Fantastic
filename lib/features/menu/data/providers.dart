/// Menu-scanner wiring.
///
/// Follows `CLAUDE.md`'s provider rule: repository/service wiring lives in
/// each feature's `data/providers.dart`, never in `application/`, so a
/// generated file that no test imports never lands inside the coverage gate
/// declaration-only files sit behind. `MenuPageReader` itself stays in
/// `application/` — only its wiring is here. #361 appends
/// `menuAnalyzerProvider` to this same file in a later wave.
library;

import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/menu/application/menu_page_reader.dart';
import 'package:fantastic/features/menu/application/remote_menu_analyzer.dart';
import 'package:fantastic/features/menu/domain/services/menu_analyzer.dart';
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

/// The composition root for the menu engine, and the **only** file that
/// names a concrete [MenuAnalyzer]. A vision-direct analyser is a second
/// class and a branch here — never an edit above this line.
///
/// `llmChatClientProvider` is M15's seam (`lib/features/diary/data/providers.dart`)
/// — reused rather than duplicated, per `design/m16_menu_scanner_research.md`
/// §4 and `CLAUDE.md`'s note that M16 does not relax the OCR no-network
/// invariant.
@riverpod
MenuAnalyzer menuAnalyzer(Ref ref) => RemoteMenuAnalyzer(
  client: ref.watch(llmChatClientProvider),
  pageReader: ref.watch(menuPageReaderProvider),
);
