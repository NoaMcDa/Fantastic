import 'package:fantastic/core/utils/list_equality.dart';
import 'package:meta/meta.dart';

/// What the page reader made of a set of photographs.
@immutable
class MenuPagesText {
  const MenuPagesText({
    required this.text,
    required this.pageCount,
    this.unreadPages = const [],
    this.ocrUnavailable = false,
  });

  /// Pages joined with a marker line; empty when nothing was read.
  final String text;

  final int pageCount;

  /// 1-based page numbers that failed OCR or read empty.
  final List<int> unreadPages;

  /// `TextRecognitionService.isAvailable` was false; nothing was attempted.
  final bool ocrUnavailable;

  /// Whether nothing at all was read.
  bool get readNothing => text.trim().isEmpty;

  MenuPagesText copyWith({
    String? text,
    int? pageCount,
    List<int>? unreadPages,
    bool? ocrUnavailable,
  }) => MenuPagesText(
    text: text ?? this.text,
    pageCount: pageCount ?? this.pageCount,
    unreadPages: unreadPages ?? this.unreadPages,
    ocrUnavailable: ocrUnavailable ?? this.ocrUnavailable,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuPagesText &&
          other.text == text &&
          other.pageCount == pageCount &&
          listEquals(other.unreadPages, unreadPages) &&
          other.ocrUnavailable == ocrUnavailable;

  @override
  int get hashCode =>
      Object.hash(text, pageCount, listHash(unreadPages), ocrUnavailable);
}
