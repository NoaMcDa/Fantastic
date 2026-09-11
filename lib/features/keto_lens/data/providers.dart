/// Keto Lens data-layer wiring.
///
/// Each provider here returns the **domain interface**, never the concrete
/// class, so nothing above `data/` can reach past the abstraction. #81's own
/// integration note named this provider `hebrewLabelParserProvider`, which
/// would have put the implementation in the name; `CLAUDE.md`'s provider rule
/// is what it is called after.
library;

import 'package:fantastic/features/keto_lens/data/parsers/hebrew_label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/services/label_parser.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The Hebrew label parser.
///
/// `keepAlive` because it is stateless and its regexes are compiled once on
/// first use. Rebuilding it per listener would recompile them.
@Riverpod(keepAlive: true)
LabelParser labelParser(Ref ref) => const HebrewLabelParser();
