import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/onboarding/data/repositories/sembast_user_profile_repository.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The onboarding feature's repository wiring.
///
/// Returns the domain interface so consumers depend on the abstraction —
/// `OnboardingService` and `macroTargetsProvider` both reach the profile
/// through this, with no knowledge that sembast is underneath.
@riverpod
UserProfileRepository userProfileRepository(Ref ref) =>
    SembastUserProfileRepository(ref.watch(databaseProvider));
