/// Keto Lens data-layer wiring.
///
/// Each provider here returns the **domain interface**, never the concrete
/// class, so nothing above `data/` can reach past the abstraction. #81's own
/// integration note named this provider `hebrewLabelParserProvider`, which
/// would have put the implementation in the name; `CLAUDE.md`'s provider rule
/// is what it is called after.
library;

import 'package:fantastic/features/keto_lens/data/adapters/text_recognizer_factory.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/ingredient_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/macro_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/data/parsers/hebrew_label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/services/ingredient_classifier.dart';
import 'package:fantastic/features/keto_lens/domain/services/macro_classifier.dart';
import 'package:fantastic/features/keto_lens/domain/services/label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The Hebrew label parser.
///
/// `keepAlive` because it is stateless and its regexes are compiled once on
/// first use. Rebuilding it per listener would recompile them.
@Riverpod(keepAlive: true)
LabelParser labelParser(Ref ref) => const HebrewLabelParser();

/// The ingredient classifier.
///
/// `keepAlive` for the same reason as [labelParser]: it is stateless, and
/// its rule lists are compile-time constants.
@Riverpod(keepAlive: true)
IngredientClassifier ingredientClassifier(Ref ref) =>
    const IngredientClassifierImpl();

/// The product-level verdict rule.
///
/// `keepAlive` for the same reason as [ingredientClassifier]: it is stateless,
/// and every threshold it reads is a compile-time constant.
@Riverpod(keepAlive: true)
MacroClassifier macroClassifier(Ref ref) => const MacroClassifierImpl();

/// On-device OCR, or the stub that says it is unavailable.
///
/// Which one is decided at compile time by the conditional export in
/// `adapters/text_recognizer_factory.dart`, not here and not at run time.
/// This provider cannot name either concrete class — that is the point of
/// the firewall.
///
/// `keepAlive` because it is stateless: the native recogniser it wraps is
/// created and closed inside each `recognise` call, so nothing is held
/// between scans.
@Riverpod(keepAlive: true)
TextRecognitionService textRecognitionService(Ref ref) =>
    createTextRecognitionService();
