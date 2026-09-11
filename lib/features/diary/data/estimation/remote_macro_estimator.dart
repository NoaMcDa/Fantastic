import 'dart:typed_data';

import 'package:fantastic/features/diary/data/estimation/estimate_response_parser.dart';
import 'package:fantastic/features/diary/data/estimation/llm_chat_client.dart';
import 'package:fantastic/features/diary/data/estimation/macro_estimation_prompt.dart';
import 'package:fantastic/features/diary/data/estimation/meal_photo_prep.dart';
import 'package:fantastic/features/diary/data/estimation/photo_bytes_reader.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';

/// [MacroEstimator] over any [LlmChatClient].
///
/// **Names no provider, and must survive the backend swap untouched.** #312's
/// product decision is that BYOK is temporary and the app will call our own
/// backend later; that swap is a new `LlmChatClient` implementation and a
/// branch in the composition root, never an edit here. If the backend later
/// owns the prompt as well, the answer is a *second* `MacroEstimator` beside
/// this one — still with no edit here.
///
/// **Both modes go through one parser.** A photo request and a text request
/// differ in the user turn and in whether an image part is attached; the
/// response schema is identical, so a second parser would only be a second
/// thing to keep in step.
class RemoteMacroEstimator implements MacroEstimator {
  const RemoteMacroEstimator({required this.client, required this.photoBytes});

  /// Public rather than private, for the reason `MealLoggingService` and
  /// `AdaptationPhaseService` both record: Dart forbids a named parameter
  /// starting with an underscore, so a `_client` field cannot use an
  /// initializing formal and trips `prefer_initializing_formals`. It is an
  /// interface, and the tests already hold it.
  final LlmChatClient client;

  /// Reads the bytes behind [estimate]'s `imagePath`.
  ///
  /// Injected rather than reached for, so this file needs no `dart:io` — it
  /// ships in the web bundle, and dart2js compiles `dart:io` as throwing
  /// stubs that `flutter analyze` and `flutter build web` both accept.
  final PhotoBytesReader photoBytes;

  @override
  Future<MealEstimate> estimate({
    String? description,
    String? imagePath,
  }) async {
    final text = description?.trim() ?? '';
    final path = imagePath?.trim() ?? '';
    if (text.isEmpty && path.isEmpty) {
      // **Before anything else**, so an empty submit costs nothing against a
      // 50-requests-a-day quota. A photo alone is enough — the model can see
      // the food without being told what it is — so this only fires when
      // there is neither.
      return const EstimateFailed(reason: EstimateFailureReason.emptyInput);
    }

    String? image;
    if (path.isNotEmpty) {
      final Uint8List? bytes;
      try {
        bytes = await photoBytes.read(path);
      } on Object catch (_) {
        // `PhotoBytesReader` promises never to throw; this catch is here
        // because a promise is not an enforcement.
        return const EstimateFailed(reason: EstimateFailureReason.badResponse);
      }
      // Unreadable bytes, an undecodable image and one too large to send are
      // one outcome from the user's seat — nothing they can retype fixes any
      // of them, and the instruction for all three is to try another photo.
      // Reported as `badResponse` rather than a new reason for exactly that.
      image = bytes == null ? null : MealPhotoPrep.prepare(bytes);
      if (image == null) {
        return const EstimateFailed(reason: EstimateFailureReason.badResponse);
      }
    }

    final ChatResult result;
    try {
      result = await client.complete(
        systemPrompt: MacroEstimationPrompt.system,
        // The photo prompt asks for the portion on the plate; the text prompt
        // cannot, having nothing to look at.
        userPrompt: image == null
            ? MacroEstimationPrompt.user(text)
            : MacroEstimationPrompt.photo(text),
        imageBase64: image,
        imageMediaType: image == null ? null : MealPhotoPrep.mediaType,
      );
    } on Object catch (_) {
      // `LlmChatClient` promises never to throw, and this catch is here
      // because a promise is not an enforcement: a future implementation that
      // breaks it must not be able to take the sheet down with it. Reported
      // as `badResponse` — the transport behaved in a way we cannot describe
      // any better than that.
      return const EstimateFailed(reason: EstimateFailureReason.badResponse);
    }

    return switch (result) {
      ChatSucceeded(:final content) => EstimateResponseParser.parse(content),
      ChatFailed(:final reason) => EstimateFailed(reason: _reasonFor(reason)),
    };
  }

  /// Maps a transport failure onto the one the UI words.
  ///
  /// Two of these are not one-to-one and both are deliberate:
  ///
  /// - **`timeout` becomes `offline`.** From the user's seat a request that
  ///   never came back and one that could not leave are the same event, and
  ///   the instruction is the same: try again when the connection is better.
  /// - **`unauthorised` becomes `notConfigured`.** #318's credentials return
  ///   null — and therefore `unauthorised` — both when no key is set and when
  ///   the provider rejected the key that is. From the user's seat those are
  ///   one instruction: go to Profile and sort the key out.
  ///   [EstimateFailureReason.unauthorised] stays in the enum for a future
  ///   backend that can tell the two apart.
  static EstimateFailureReason _reasonFor(ChatFailureReason reason) =>
      switch (reason) {
        ChatFailureReason.offline => EstimateFailureReason.offline,
        ChatFailureReason.timeout => EstimateFailureReason.offline,
        ChatFailureReason.unauthorised => EstimateFailureReason.notConfigured,
        ChatFailureReason.rateLimited => EstimateFailureReason.rateLimited,
        ChatFailureReason.badResponse => EstimateFailureReason.badResponse,
      };
}
