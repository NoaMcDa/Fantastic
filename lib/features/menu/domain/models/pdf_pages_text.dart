import 'package:fantastic/core/utils/list_equality.dart';
import 'package:meta/meta.dart';

/// What [PdfPageExtractor] made of a PDF's text layer, page by page.
///
/// Deliberately shaped like [MenuPagesText] — a `Map` in place of the joined
/// `String` there, because a PDF's pages are read all at once rather than
/// streamed one at a time with a progress callback, so there is no reason to
/// commit to page order before [joined] is asked for.
@immutable
class PdfPagesText {
  const PdfPagesText({
    required this.pages,
    required this.pageCount,
    this.pagesWithoutTextLayer = const [],
  });

  /// Extracted text per page, in page order, for pages that had a usable
  /// text layer. Pages listed in [pagesWithoutTextLayer] are absent.
  final Map<int, String> pages;

  final int pageCount;

  /// 1-based page numbers with no usable text layer — either genuinely
  /// absent, or present but illegible (the legibility guard in
  /// `PdfrxPageExtractor`). These are what the rasterise issue renders to
  /// images for OCR.
  final List<int> pagesWithoutTextLayer;

  /// Whether no page yielded usable text.
  bool get readNothing => pages.values.every((text) => text.trim().isEmpty);

  /// The pages joined for the model, under the same marker line
  /// `MenuPageReader.pageMarker` writes for a photographed menu, so a PDF
  /// and a photographed menu look identical to the prompt.
  ///
  /// [_pageMarker] duplicates that format rather than importing
  /// `MenuPageReader` — that class lives in `application/`, and `CLAUDE.md`'s
  /// layer rules run one way: `domain/` may not depend on `application/`,
  /// even for a static, stateless helper. The two are pinned equal by
  /// `pdf_pages_text_test.dart`.
  String get joined {
    final pageNumbers = pages.keys.toList()..sort();
    final buffer = StringBuffer();
    for (final page in pageNumbers) {
      buffer
        ..writeln(_pageMarker(page))
        ..writeln(pages[page])
        ..writeln();
    }
    return buffer.toString().trim();
  }

  PdfPagesText copyWith({
    Map<int, String>? pages,
    int? pageCount,
    List<int>? pagesWithoutTextLayer,
  }) => PdfPagesText(
    pages: pages ?? this.pages,
    pageCount: pageCount ?? this.pageCount,
    pagesWithoutTextLayer: pagesWithoutTextLayer ?? this.pagesWithoutTextLayer,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPagesText &&
          _mapEquals(other.pages, pages) &&
          other.pageCount == pageCount &&
          listEquals(other.pagesWithoutTextLayer, pagesWithoutTextLayer);

  @override
  int get hashCode =>
      Object.hash(_mapHash(pages), pageCount, listHash(pagesWithoutTextLayer));
}

/// Mirrors `MenuPageReader.pageMarker` — see the doc comment on
/// [PdfPagesText.joined] for why this is a duplicate rather than an import.
String _pageMarker(int page) => '--- עמוד $page ---';

/// Element-wise map comparison. `package:collection`'s `mapEquals` lives in
/// `package:flutter/foundation.dart`, which `domain/` may not import — the
/// same reason [listEquals] exists in `lib/core/utils/list_equality.dart`.
bool _mapEquals(Map<int, String> a, Map<int, String> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _mapHash(Map<int, String> map) {
  final keys = map.keys.toList()..sort();
  return Object.hashAll([for (final key in keys) Object.hash(key, map[key])]);
}
