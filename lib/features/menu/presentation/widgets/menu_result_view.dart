import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/menu/domain/models/analysed_dish.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/presentation/widgets/dish_card.dart';
import 'package:fantastic/features/menu/presentation/widgets/dish_verdict_badge.dart';
import 'package:flutter/material.dart';

/// Renders a [MenuAnalysed] as three verdict groups, an unclassified
/// section, a legend and, when there are any, an unread-pages warning.
///
/// A pure function of [analysis] — no provider, so every state renders from a
/// fixture alone (`design/m16_menu_scanner_research.md` §7). `MenuAnalysis`'s
/// other branch, `MenuAnalysisFailed`, never reaches this widget: the screen
/// that owns the provider handles that case before building this one.
///
/// **Red is grouped and counted, never hidden**, and **unclassified is
/// rendered, never dropped** — the two safety rules this widget exists to
/// honour (`design/m16_menu_scanner_research.md` §3, rules 3 and 4). The red
/// group's count stays on screen whether or not the group is expanded; that
/// is the whole point of grouping over filtering.
class MenuResultView extends StatefulWidget {
  const MenuResultView({
    required this.analysis,
    this.redInitiallyExpanded = false,
    super.key,
  });

  /// The result to render.
  final MenuAnalysed analysis;

  /// Whether the red group starts expanded. Defaults to collapsed — a menu
  /// with several non-keto dishes should not open on a wall of red.
  final bool redInitiallyExpanded;

  @override
  State<MenuResultView> createState() => _MenuResultViewState();
}

class _MenuResultViewState extends State<MenuResultView> {
  late bool _redExpanded = widget.redInitiallyExpanded;

  void _toggleRed() => setState(() => _redExpanded = !_redExpanded);

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final green = analysis.withVerdict(DishVerdict.orderAsIs);
    final yellow = analysis.withVerdict(DishVerdict.modifiable);
    final red = analysis.withVerdict(DishVerdict.nonKeto);
    final unclassified = analysis.unclassified;
    final unreadPages = analysis.unreadPages;
    // "Saw dishes, placed none" — every name from the reply landed in
    // `unclassified` and none earned a verdict. Not the same as an empty
    // *result*: `dishes` and `unclassified` empty together never reaches
    // this widget, since a `MenuAnalysed` with nothing in either field is
    // not a state the analyser produces.
    final noDishesClassified =
        analysis.dishes.isEmpty && unclassified.isNotEmpty;

    return CustomScrollView(
      slivers: [
        if (unreadPages.isNotEmpty)
          SliverToBoxAdapter(child: _UnreadPagesNotice(pages: unreadPages)),
        SliverPadding(
          padding: const EdgeInsetsDirectional.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _Legend(),
              if (green.isNotEmpty) ...[
                _SectionHeading(
                  key: const Key('menu_orderAsIs_heading'),
                  label: MenuCopy.orderAsIsHeading,
                  count: green.length,
                ),
                for (final dish in green) DishCard(dish: dish),
              ],
              if (yellow.isNotEmpty) ...[
                _SectionHeading(
                  key: const Key('menu_modifiable_heading'),
                  label: MenuCopy.modifiableHeading,
                  count: yellow.length,
                ),
                for (final dish in yellow) DishCard(dish: dish),
              ],
              if (red.isNotEmpty)
                _RedGroup(
                  dishes: red,
                  expanded: _redExpanded,
                  onToggle: _toggleRed,
                ),
              if (noDishesClassified)
                Padding(
                  key: const Key('menu_no_dishes_note'),
                  padding: const EdgeInsetsDirectional.only(top: 16, bottom: 8),
                  child: Text(
                    MenuCopy.noDishesClassifiedNote,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (unclassified.isNotEmpty)
                _UnclassifiedSection(names: unclassified),
            ]),
          ),
        ),
      ],
    );
  }
}

/// A heading combining a Hebrew label with a count — `אפשר להזמין (3)` — as
/// two separate [Text]s so the count renders `TextDirection.ltr` without
/// affecting the label around it.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label, required this.count, super.key});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 16, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: style),
          const SizedBox(width: 4),
          Text('($count)', style: style, textDirection: TextDirection.ltr),
        ],
      ),
    );
  }
}

/// The three-chip legend, rendered from [MenuVerdictRules.definitions] so the
/// user reads the same sentence the model was prompted with.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('menu_legend'),
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final verdict in DishVerdict.displayOrder)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DishVerdictBadge(verdict: verdict),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        MenuVerdictRules.definitions[verdict]!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The warning line at the top naming the pages OCR could not read. Caution
/// colouring, not danger — the rest of the analysis is still good, this is a
/// warning, not a failure.
class _UnreadPagesNotice extends StatelessWidget {
  const _UnreadPagesNotice({required this.pages});

  final List<int> pages;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('menu_unread_pages'),
    width: double.infinity,
    color: AppTheme.caution,
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            MenuCopy.unreadPagesLine(pages),
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The collapsed-by-default red group: a tappable header whose count is
/// visible whether or not the group is expanded, and the red [DishCard]s
/// underneath it once it is.
///
/// `AnimatedSize`, not `AnimatedCrossFade` — the latter keeps both children
/// mounted (`design/m2_handoff.md`), which would leave a hidden red dish
/// findable in the widget tree while reading as collapsed on screen.
class _RedGroup extends StatelessWidget {
  const _RedGroup({
    required this.dishes,
    required this.expanded,
    required this.onToggle,
  });

  final List<AnalysedDish> dishes;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            // Keyed on the header itself, not the surrounding `Card`: once
            // expanded the card grows to hold the red `DishCard`s below, and
            // a key on the card would move a tap aimed at its centre off the
            // header and onto whatever dish card now sits there.
            key: const Key('menu_red_header'),
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(12),
                child: Row(
                  children: [
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        MenuCopy.nonKetoHeading,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '(${dishes.length})',
                      style: theme.textTheme.titleMedium,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: AlignmentDirectional.topStart,
            child: expanded
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 12,
                      end: 12,
                      bottom: 12,
                    ),
                    child: Column(
                      children: [
                        for (final dish in dishes) DishCard(dish: dish),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// `MenuAnalysed.unclassified` — reported, never dropped. No colour: these
/// are not a fourth verdict, they are names the model could not place.
class _UnclassifiedSection extends StatelessWidget {
  const _UnclassifiedSection({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('menu_unclassified'),
      margin: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MenuCopy.unclassifiedHeading,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(width: 4),
                Text(
                  '(${names.length})',
                  style: theme.textTheme.titleMedium,
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              MenuCopy.unclassifiedNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final name in names)
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(vertical: 2),
                child: Text(name),
              ),
          ],
        ),
      ),
    );
  }
}
