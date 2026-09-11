import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/features/menu/application/menu_page_reader.dart';
import 'package:fantastic/features/menu/data/analysis/menu_analysis_prompt.dart';
import 'package:fantastic/features/menu/data/analysis/menu_response_parser.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:fantastic/features/menu/domain/models/menu_pages_text.dart';
import 'package:fantastic/features/menu/domain/services/menu_analyzer.dart';

/// [MenuAnalyzer] over any [LlmChatClient], with photographs read on the
/// device first.
///
/// **Names no provider, and must survive a backend swap untouched.** This
/// class depends only on [LlmChatClient] and [MenuPageReader] — both
/// interfaces — plus the static, transport-agnostic [MenuAnalysisPrompt] and
/// [MenuResponseParser]. A vision-direct analyser — the documented swap if
/// the corpus shows OCR is the bottleneck — is a second [MenuAnalyzer]
/// implementation selected in one provider, never an edit here. The word
/// "OpenRouter" appears nowhere below.
///
/// **OCR runs first and on the device.** Any photographs are handed to
/// [pageReader] before anything reaches the network; what [client] ever
/// sees is text. That is Epic #351's first architectural invariant, and this
/// class is where it is kept: no method here ever builds an image part.
///
/// **One request per menu.** Every page's recognised text, plus any pasted
/// text, is joined into a single [LlmChatClient.complete] call — never one
/// call per page.
class RemoteMenuAnalyzer implements MenuAnalyzer {
  const RemoteMenuAnalyzer({required this.client, required this.pageReader});

  // Public rather than private, for the reason `ScanOrchestrator` and
  // `RemoteMacroEstimator` both record: Dart forbids a named parameter
  // starting with an underscore, so a `_client` field cannot use an
  // initializing formal and trips `prefer_initializing_formals`. They are
  // interfaces; nothing leaks.
  final LlmChatClient client;
  final MenuPageReader pageReader;

  @override
  Future<MenuAnalysis> analyse({
    String? text,
    List<String> imagePaths = const [],
    void Function(int page, int of)? onPage,
  }) async {
    final pastedText = text?.trim() ?? '';
    if (pastedText.isEmpty && imagePaths.isEmpty) {
      // **Before anything else** — an empty submit costs no OCR and no
      // quota against a 50-requests-a-day free tier.
      return const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.emptyInput,
      );
    }

    var pages = const MenuPagesText(text: '', pageCount: 0);
    if (imagePaths.isNotEmpty) {
      try {
        pages = await pageReader.read(imagePaths, onPage: onPage);
      } on Object catch (_) {
        // `MenuPageReader.read` promises never to throw; this catch is here
        // because a promise is not an enforcement — a future implementation
        // that breaks it must not be able to take the screen down with it.
        return const MenuAnalysisFailed(
          reason: MenuAnalysisFailureReason.badResponse,
        );
      }

      if (pages.ocrUnavailable && pastedText.isEmpty) {
        return const MenuAnalysisFailed(
          reason: MenuAnalysisFailureReason.ocrUnavailable,
        );
      }
      if (pages.readNothing && pastedText.isEmpty) {
        return const MenuAnalysisFailed(
          reason: MenuAnalysisFailureReason.noTextFound,
        );
      }
    }

    final source = [
      pastedText,
      pages.text,
    ].where((part) => part.trim().isNotEmpty).join('\n\n');

    final ChatResult result;
    try {
      result = await client.complete(
        systemPrompt: MenuAnalysisPrompt.system,
        userPrompt: MenuAnalysisPrompt.user(source),
        maxOutputTokens: MenuVerdictRules.maxOutputTokens,
        responseSchema: MenuAnalysisPrompt.schema,
        // No image part, ever — everything the client sees is text that has
        // already been recognised on the device.
      );
    } on Object catch (_) {
      // `LlmChatClient` promises never to throw, and this catch is here for
      // the same reason as above: reported as `badResponse` — the transport
      // behaved in a way we cannot describe any better than that.
      return const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
    }

    return switch (result) {
      ChatSucceeded(:final content) => _withPageMetadata(
        MenuResponseParser.parse(content, sourceText: source),
        pages,
      ),
      ChatFailed(:final reason) => MenuAnalysisFailed(
        reason: _reasonFor(reason),
      ),
    };
  }

  /// Fills [MenuAnalysed.pageCount] and [MenuAnalysed.unreadPages] from
  /// [pages] onto [analysis]. `MenuResponseParser.parse` knows nothing about
  /// OCR and always returns zeros for both, so this is the one place that
  /// completes them. A [MenuAnalysisFailed] passes through unchanged — a
  /// failure carries no page metadata to attach.
  static MenuAnalysis _withPageMetadata(
    MenuAnalysis analysis,
    MenuPagesText pages,
  ) => switch (analysis) {
    MenuAnalysed(:final dishes, :final unclassified) => MenuAnalysed(
      dishes: dishes,
      unclassified: unclassified,
      pageCount: pages.pageCount,
      unreadPages: pages.unreadPages,
    ),
    MenuAnalysisFailed() => analysis,
  };

  /// Maps a transport failure onto the one the UI words.
  ///
  /// Two of these are not one-to-one and both are deliberate, and both are
  /// exactly the reasons `RemoteMacroEstimator._reasonFor` gives:
  ///
  /// - **`timeout` becomes `offline`.** From the user's seat a request that
  ///   never came back and one that could not leave are the same event, and
  ///   the instruction is the same: try again when the connection is better.
  /// - **`unauthorised` becomes `notConfigured`.** #319's credentials return
  ///   null — and therefore `unauthorised` — both when no key is set and when
  ///   the provider rejected the key that is. From the user's seat those are
  ///   one instruction: go to Profile and sort the key out.
  ///   [MenuAnalysisFailureReason.unauthorised] stays in the enum for a
  ///   future backend that can tell the two apart.
  static MenuAnalysisFailureReason _reasonFor(ChatFailureReason reason) =>
      switch (reason) {
        ChatFailureReason.offline => MenuAnalysisFailureReason.offline,
        ChatFailureReason.timeout => MenuAnalysisFailureReason.offline,
        ChatFailureReason.unauthorised =>
          MenuAnalysisFailureReason.notConfigured,
        ChatFailureReason.rateLimited => MenuAnalysisFailureReason.rateLimited,
        ChatFailureReason.badResponse => MenuAnalysisFailureReason.badResponse,
      };
}
