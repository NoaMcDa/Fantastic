import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VerdictBadge.worst', () {
    test('returns nonKeto when the list contains it', () {
      expect(
        VerdictBadge.worst([VerdictBadge.cleanKeto, VerdictBadge.nonKeto]),
        VerdictBadge.nonKeto,
      );
    });

    test('nonKeto wins over cautionQuantityDependent', () {
      expect(
        VerdictBadge.worst([
          VerdictBadge.cautionQuantityDependent,
          VerdictBadge.nonKeto,
        ]),
        VerdictBadge.nonKeto,
      );
    });

    test('returns cautionQuantityDependent over cleanKeto', () {
      expect(
        VerdictBadge.worst([
          VerdictBadge.cleanKeto,
          VerdictBadge.cautionQuantityDependent,
        ]),
        VerdictBadge.cautionQuantityDependent,
      );
    });

    test('returns cleanKeto when every badge is clean', () {
      expect(
        VerdictBadge.worst([VerdictBadge.cleanKeto, VerdictBadge.cleanKeto]),
        VerdictBadge.cleanKeto,
      );
    });

    test('returns cleanKeto for an empty list', () {
      // Nothing flagged means nothing wrong.
      expect(VerdictBadge.worst(const []), VerdictBadge.cleanKeto);
    });

    test('is order-independent', () {
      expect(
        VerdictBadge.worst([VerdictBadge.nonKeto, VerdictBadge.cleanKeto]),
        VerdictBadge.worst([VerdictBadge.cleanKeto, VerdictBadge.nonKeto]),
      );
    });

    test('handles a single-element list', () {
      expect(
        VerdictBadge.worst([VerdictBadge.cautionQuantityDependent]),
        VerdictBadge.cautionQuantityDependent,
      );
    });
  });

  group('VerdictBadge', () {
    test('has exactly three values', () {
      expect(VerdictBadge.values.length, 3);
    });
  });
}
