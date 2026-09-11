import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';

/// Converts between [EstimationSettings] and its sembast record shape.
///
/// Called only by `SembastEstimationSettingsRepository`. The values are a
/// `String?` and a `bool`, both JSON-compatible as they stand — none of the
/// three encoding rules in `CLAUDE.md` §Local Persistence applies, because
/// there is no `DateTime`, no enum and no number here.
abstract final class EstimationSettingsMapper {
  /// The record every write is pinned to. There is exactly one.
  static const int singletonId = 0;

  static Map<String, Object?> toRecord(EstimationSettings settings) => {
    'apiKey': settings.apiKey,
    'consentAccepted': settings.consentAccepted,
  };

  static EstimationSettings fromRecord(Map<String, Object?> record) =>
      EstimationSettings(
        apiKey: record['apiKey'] as String?,
        // Defaulted rather than force-unwrapped, and defaulted to **false**: a
        // record written by an older build has no such key, and a missing
        // consent flag has to fail closed. Reading it as accepted would send a
        // user's meal description to a third party on the strength of a key
        // that is absent from the record.
        consentAccepted: record['consentAccepted'] as bool? ?? false,
      );
}
