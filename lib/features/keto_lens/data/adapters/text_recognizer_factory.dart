/// Chooses an OCR implementation for whichever platform this is compiled
/// for.
///
/// The import is resolved at compile time, not with a `kIsWeb` branch: a
/// runtime check would still link `google_mlkit_text_recognition` into the
/// web bundle, which defeats the purpose. Defaulting to the unavailable
/// implementation and switching on `dart.library.io` — rather than the other
/// way round — means every non-VM target gets the safe half, including ones
/// that do not exist yet.
///
/// Exactly the shape of `lib/core/database/database_factory.dart`, which
/// `CLAUDE.md`'s layer rules call "the web build's only firewall". This is
/// the second one.
///
/// Exposes `createTextRecognitionService()`. `textRecognitionServiceProvider`
/// in `data/providers.dart` is the only caller.
library;

export 'unavailable_text_recognizer.dart'
    if (dart.library.io) 'ml_kit_text_recognizer.dart';
