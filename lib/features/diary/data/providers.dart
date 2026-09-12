import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/core/services/llm/llm_credentials.dart';
import 'package:fantastic/core/services/llm/open_router_client.dart';
import 'package:fantastic/features/diary/data/estimation/photo_bytes_reader.dart';
import 'package:fantastic/features/diary/data/estimation/remote_macro_estimator.dart';
import 'package:fantastic/features/diary/data/estimation/user_api_key_credentials.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_estimation_settings_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_meal_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_symptom_log_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The diary feature's repository wiring.
///
/// Every provider returns the **domain interface**, not the sembast class, so
/// a consumer cannot reach past the abstraction to a store-specific method —
/// the layer rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.
@riverpod
MealRepository mealRepository(Ref ref) =>
    SembastMealRepository(ref.watch(databaseProvider));

@riverpod
SymptomLogRepository symptomLogRepository(Ref ref) =>
    SembastSymptomLogRepository(ref.watch(databaseProvider));

@riverpod
EstimationSettingsRepository estimationSettingsRepository(Ref ref) =>
    SembastEstimationSettingsRepository(ref.watch(databaseProvider));

@riverpod
LlmCredentials estimationCredentials(Ref ref) =>
    UserApiKeyCredentials(ref.watch(estimationSettingsRepositoryProvider));

/// The composition root for the estimator's transport, and **the only place
/// besides `open_router_client.dart` where a concrete provider is named**.
///
/// Adding our own backend later means a new implementation file and a new
/// branch here — never an edit anywhere above this line. Epic #312's OCP
/// invariant, enforced by the return type: this hands back the interface.
///
/// `ref.onDispose` closes the socket, so a test that overrides this with a
/// `MockClient` leaks nothing and a disposed container holds no connection.
///
/// **`keepAlive`, and it is load-bearing rather than an optimisation (#419).**
/// Every screen that estimates — `AddMealDescriptionSheet`, `AddMealPhotoSheet`,
/// `MenuScannerScreen`, and `RecipeConverterScreen`'s #396 suggestion pass —
/// reaches its engine with a bare `ref.read` inside a button handler and holds
/// no listener, because the result is awaited once rather than watched. An autoDispose client is therefore disposed one frame
/// into the request, `ref.onDispose` closes the `http.Client` under it, and
/// **closing a client cancels what it is carrying**: `BrowserClient.close`
/// aborts every open `fetch` and `IOClient.close` force-closes the socket.
/// `OpenRouterClient` sees the resulting `ClientException` and reports
/// [ChatFailureReason.offline], which the sheets word as "אין חיבור
/// לאינטרנט" — instantly, on a working connection. That was the user-visible
/// bug #411 and #414 each mistook for a retired model id and a slow one.
///
/// One `http.Client` for the app's lifetime is what `package:http` recommends
/// anyway. `onDispose` still runs when the container itself goes, so nothing
/// leaks. Do not "tidy" this back to `@riverpod`: the regression test is
/// `test/features/diary/data/estimation/llm_chat_client_lifecycle_test.dart`.
///
/// That test guards the mechanism for **every** consumer, which is why
/// `substitutionSuggesterProvider` (M10) needs no twin of it: the suggester is
/// autoDispose and *is* disposed a frame into its request, but it owns no
/// `onDispose` and merely holds the client this provider keeps open. The
/// dependents list above is the thing to keep current — a consumer missing
/// from it is a consumer whose breakage nobody will predict.
@Riverpod(keepAlive: true)
LlmChatClient llmChatClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenRouterClient(
    httpClient: client,
    credentials: ref.watch(estimationCredentialsProvider),
  );
}

/// The composition root for estimation, and the only place a concrete
/// estimator is named.
///
/// A backend that owns the prompt as well becomes a second `MacroEstimator`
/// implementation selected here — no edit anywhere above this line. Returns
/// the interface for the same reason every repository provider does.
/// Reads a picked photo's bytes.
///
/// A provider of its own, rather than a `const` inside the estimator, so a
/// test can supply bytes without a file system and the browser build never
/// needs `dart:io` to be conditionally exported.
@riverpod
PhotoBytesReader photoBytesReader(Ref ref) => const XFilePhotoBytesReader();

@riverpod
MacroEstimator macroEstimator(Ref ref) => RemoteMacroEstimator(
  client: ref.watch(llmChatClientProvider),
  photoBytes: ref.watch(photoBytesReaderProvider),
);
