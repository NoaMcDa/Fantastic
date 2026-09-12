import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';

/// The outermost seam of the menu scanner.
///
/// `{text, imagePaths}` mirrors `MacroEstimator.estimate({description,
/// imagePath})` so a vision implementation can take the photos and the text
/// implementation the text, behind one method, with the choice made in one
/// provider — Epic #351's open/closed invariant.
abstract interface class MenuAnalyzer {
  /// **Never throws.** Every outcome is a [MenuAnalysis]. Both [text] and
  /// [imagePaths] empty → [MenuAnalysisFailureReason.emptyInput].
  ///
  /// [onPage] reports OCR progress as `(page, of)` before each page is read.
  /// Ignored by an implementation that has no pages to read — a text-only
  /// analyser simply never calls it.
  Future<MenuAnalysis> analyse({
    String? text,
    List<String> imagePaths = const [],
    void Function(int page, int of)? onPage,
  });
}
