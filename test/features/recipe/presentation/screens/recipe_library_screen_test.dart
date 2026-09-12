import 'dart:async';

import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockSavedRecipeRepository extends Mock
    implements SavedRecipeRepository {}

void main() {
  late _MockSavedRecipeRepository repository;

  /// The recipes the provider currently serves — mutated by the mocked
  /// `deleteById`, mirroring `MealListSection`'s own test double: production
  /// invalidates the provider after a delete, the refetch hits a repository
  /// the row is (or is not) gone from, and the row leaves — or does not
  /// leave — the tree accordingly.
  late List<SavedRecipe> stored;

  setUp(() {
    stored = [];
    repository = _MockSavedRecipeRepository();
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    required List<SavedRecipe> recipes,
  }) {
    stored = recipes;
    return pumpApp(
      tester,
      const RecipeLibraryScreen(),
      overrides: [
        savedRecipesProvider.overrideWith((ref) async => stored),
        savedRecipeRepositoryProvider.overrideWithValue(repository),
      ],
    );
  }

  group('rendering', () {
    testWidgets('renders one card per recipe, in provider order', (
      tester,
    ) async {
      final newer = SavedRecipeFixture.fixture(id: 5, title: 'חדש');
      final older = SavedRecipeFixture.fixture(id: 3, title: 'ישן');

      await pumpLibrary(tester, recipes: [newer, older]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saved_recipe_5')), findsOneWidget);
      expect(find.byKey(const Key('saved_recipe_3')), findsOneWidget);

      // "Newest first" is the provider's contract (repository contract
      // test); this only checks the screen renders in the order it is
      // given rather than re-sorting or reversing it.
      final newerTop = tester
          .getTopLeft(find.byKey(const Key('saved_recipe_5')))
          .dy;
      final olderTop = tester
          .getTopLeft(find.byKey(const Key('saved_recipe_3')))
          .dy;
      expect(newerTop, lessThan(olderTop));
    });

    testWidgets('shows the ingredient and substituted counts', (tester) async {
      await pumpLibrary(
        tester,
        recipes: [
          SavedRecipeFixture.fixture(
            id: 1,
            outcomes: SavedRecipeFixture.allOutcomeVariants(),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // 5 outcomes total, 2 of which are `Substituted`.
      expect(find.text('5 מצרכים · 2 הוחלפו'), findsOneWidget);
    });

    testWidgets('loading renders a static skeleton, no spinner', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const RecipeLibraryScreen(),
        overrides: [
          savedRecipesProvider.overrideWith(
            (ref) => Completer<List<SavedRecipe>>().future,
          ),
          savedRecipeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('recipe_library_list')), findsNothing);
    });

    testWidgets('error renders loadFailed and no skeleton', (tester) async {
      await pumpApp(
        tester,
        const RecipeLibraryScreen(),
        overrides: [
          savedRecipesProvider.overrideWith(
            (ref) async => throw Exception('disk gone'),
          ),
          savedRecipeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(RecipeCopy.loadFailed), findsOneWidget);
      expect(find.byKey(const Key('recipe_library_list')), findsNothing);
    });

    testWidgets('empty renders the empty state, distinguishable from error', (
      tester,
    ) async {
      await pumpLibrary(tester, recipes: []);
      await tester.pumpAndSettle();

      expect(find.text(RecipeCopy.emptyLibraryTitle), findsOneWidget);
      expect(find.text(RecipeCopy.emptyLibraryBody), findsOneWidget);
      expect(find.byKey(const Key('recipe_library_load_failed')), findsNothing);
      expect(find.text(RecipeCopy.loadFailed), findsNothing);
    });

    // riverpod 3's retry state is an `AsyncLoading` *carrying* an error —
    // `isLoading` and `hasError` both true. A test driven only by
    // `invalidate` never reaches it (`AsyncValue.when`'s
    // `skipLoadingOnRefresh: true` default renders the error correctly
    // regardless, which is why this project does not use `when` at all and
    // why this screen must not either). Only arming the real retry via
    // `ProviderElement.triggerRetry` proves anything here — see
    // `design/user_bugs_handoff.md` and
    // `meal_list_section_test.dart`'s identical test.
    testWidgets('says so while a failed first read is being retried', (
      tester,
    ) async {
      final container = ProviderContainer(
        retry: (retryCount, _) =>
            retryCount == 0 ? const Duration(milliseconds: 20) : null,
        overrides: [
          savedRecipesProvider.overrideWith(
            (ref) async => throw Exception('disk gone'),
          ),
          savedRecipeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: RecipeLibraryScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final state = container.read(savedRecipesProvider);
      expect(
        state.isLoading && state.hasError,
        isTrue,
        reason: 'this test only means anything in the retrying state',
      );

      expect(find.text(RecipeCopy.loadFailed), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('recipe_library_list')), findsNothing);

      // Let the one armed retry fire, so nothing is pending at teardown.
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pumpAndSettle();
    });
  });

  group('navigation', () {
    testWidgets('tap pushes /recipe/saved/:id', (tester) async {
      String? pushed;
      final recipe = SavedRecipeFixture.fixture(id: 7, title: 'לחיצה');
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const RecipeLibraryScreen()),
          GoRoute(
            path: '/recipe/saved/:id',
            builder: (_, state) {
              pushed = state.uri.toString();
              return const SizedBox.shrink();
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            savedRecipesProvider.overrideWith((ref) async => [recipe]),
            savedRecipeRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('לחיצה'));
      await tester.pumpAndSettle();

      expect(pushed, '/recipe/saved/7');
    });
  });

  group('swipe to delete', () {
    // The app runs RTL, where the start edge is the right — an `endToStart`
    // dismissal travels *rightward*, a positive dx
    // (`design/m2_handoff.md`).
    const dismissSwipe = Offset(500, 0);

    testWidgets('dismiss deletes the recipe', (tester) async {
      when(() => repository.deleteById(7)).thenAnswer(
        (_) async => stored = stored.where((r) => r.id != 7).toList(),
      );

      await pumpLibrary(
        tester,
        recipes: [SavedRecipeFixture.fixture(id: 7, title: 'למחיקה')],
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('למחיקה'), dismissSwipe);
      await tester.pumpAndSettle();

      verify(() => repository.deleteById(7)).called(1);
      expect(find.text('למחיקה'), findsNothing);
    });

    // The core of the async-delete trap `MealListSection` already solved:
    // `Dismissible` removes the row from the tree the instant the gesture
    // completes, but the delete is asynchronous. A failed delete must not
    // leave the row gone from the screen while it is still in the store —
    // it has to come back, and the failure has to be visible.
    testWidgets('a failed delete restores the row and shows deleteFailed', (
      tester,
    ) async {
      when(() => repository.deleteById(2))
          .thenThrow(const PersistenceException('boom', 'disk gone'));

      await pumpLibrary(
        tester,
        recipes: [SavedRecipeFixture.fixture(id: 2, title: 'לא נמחק')],
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('לא נמחק'), dismissSwipe);
      await tester.pumpAndSettle();

      verify(() => repository.deleteById(2)).called(1);
      // The row is back — the store and the screen agree again.
      expect(find.text('לא נמחק'), findsOneWidget);
      expect(find.text(RecipeCopy.deleteFailed), findsOneWidget);
    });

    testWidgets(
      'a recipe with no id renders un-dismissible instead of throwing',
      (tester) async {
        await pumpLibrary(
          tester,
          recipes: [SavedRecipeFixture.fixture(title: 'לא נשמר עדיין')],
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('לא נשמר עדיין'), findsOneWidget);
        expect(find.byType(Dismissible), findsNothing);
      },
    );
  });
}
