import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/features/menu/domain/models/analysed_dish.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/presentation/widgets/dish_verdict_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One dish, collapsed to its name and badge, expanding on tap to its `why`
/// and — for a modifiable dish — the full instruction with a copy button.
///
/// A `StatefulWidget` owning one bool: no provider, so every state renders
/// from a fixture alone. Never `AnimatedCrossFade` for the expand/collapse —
/// it keeps both children mounted (`design/m2_handoff.md`) — `AnimatedSize`
/// is used instead, over a finite duration so `pumpAndSettle` always settles.
class DishCard extends StatefulWidget {
  const DishCard({
    required this.dish,
    this.initiallyExpanded = false,
    super.key,
  });

  final AnalysedDish dish;

  /// Whether the card starts expanded. Defaults to collapsed.
  final bool initiallyExpanded;

  @override
  State<DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<DishCard> {
  late bool _expanded = widget.initiallyExpanded;

  AnalysedDish get _dish => widget.dish;

  /// A `modifiable` dish whose `modification` is null cannot reach this
  /// widget in production (the parser demotes it first) — but a fixture can
  /// build one, so nothing renders for the instruction rather than an empty
  /// heading.
  bool get _hasInstruction =>
      _dish.verdict == DishVerdict.modifiable && _dish.modification != null;

  /// The first line of the instruction — the value shown collapsed, so a
  /// yellow never hides it behind a tap the user at a table will not make.
  String? get _firstInstructionLine {
    final modification = _dish.modification;
    if (modification == null) {
      return null;
    }
    final newline = modification.indexOf('\n');
    return newline == -1 ? modification : modification.substring(0, newline);
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  Future<void> _copyInstruction() async {
    final modification = _dish.modification;
    if (modification == null) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: modification));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(MenuCopy.copiedConfirmation)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: Key('dish_card_${_dish.name}'),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsetsDirectional.symmetric(vertical: 4),
      child: InkWell(
        onTap: _toggleExpanded,
        child: ConstrainedBox(
          // 44pt is the Apple HIG minimum touch target, and the whole row is
          // the tap target here.
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      // Wraps, never overflows: the name is whatever the
                      // menu printed and can run long.
                      child: Text(
                        _dish.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DishVerdictBadge(verdict: _dish.verdict),
                  ],
                ),
                if (_dish.description case final description?) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (!_expanded && _hasInstruction) ...[
                  const SizedBox(height: 4),
                  Text(
                    _firstInstructionLine!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: AlignmentDirectional.topStart,
                  child: _expanded
                      ? _ExpandedBody(dish: _dish, onCopy: _copyInstruction)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The `why` block and, for a modifiable dish, the `מה לבקש` block with its
/// copy button. Split out so [DishCard.build] stays a single readable tree.
class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({required this.dish, required this.onCopy});

  final AnalysedDish dish;
  final VoidCallback onCopy;

  bool get _hasInstruction =>
      dish.verdict == DishVerdict.modifiable && dish.modification != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Text(MenuCopy.whyHeading, style: theme.textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(dish.why, key: Key('dish_why_${dish.name}')),
        if (_hasInstruction) ...[
          const SizedBox(height: 8),
          Text(MenuCopy.modificationHeading, style: theme.textTheme.labelLarge),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  dish.modification!,
                  key: Key('dish_modification_${dish.name}'),
                ),
              ),
              IconButton(
                key: Key('dish_copy_instruction_${dish.name}'),
                icon: const Icon(Icons.copy),
                tooltip: MenuCopy.copyInstructionTooltip,
                onPressed: onCopy,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
