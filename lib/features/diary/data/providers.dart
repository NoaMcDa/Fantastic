import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/diary/data/estimation/estimation_credentials.dart';
import 'package:fantastic/features/diary/data/estimation/llm_chat_client.dart';
import 'package:fantastic/features/diary/data/estimation/open_router_client.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_estimation_settings_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_meal_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_symptom_log_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
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
EstimationCredentials estimationCredentials(Ref ref) =>
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
@riverpod
LlmChatClient llmChatClient(Ref ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenRouterClient(
    httpClient: client,
    credentials: ref.watch(estimationCredentialsProvider),
  );
}
