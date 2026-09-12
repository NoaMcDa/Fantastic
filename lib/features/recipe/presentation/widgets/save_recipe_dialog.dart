import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:flutter/material.dart';

/// Asks for a title before a conversion is saved.
///
/// A dialog, not a bottom sheet: the whole interaction is one field and two
/// buttons, and the conversion behind it is unaffected either way.
///
/// Validation lives here, not on [SavedRecipe] — the repo's convention is
/// that domain models carry no constructor asserts (`SavedRecipeFixture`'s
/// own comment), so an empty title is refused before a save is ever
/// attempted, not after.
class SaveRecipeDialog extends StatefulWidget {
  const SaveRecipeDialog({this.initialTitle, super.key});

  /// Seeds the field — the reopened-recipe path passes the recipe's current
  /// title so re-saving does not silently blank it.
  final String? initialTitle;

  static const int maxTitleLength = 60;

  /// Shows the dialog and resolves to the trimmed title, or null on cancel.
  static Future<String?> show(BuildContext context, {String? initialTitle}) =>
      showDialog<String>(
        context: context,
        builder: (_) => SaveRecipeDialog(initialTitle: initialTitle),
      );

  @override
  State<SaveRecipeDialog> createState() => _SaveRecipeDialogState();
}

class _SaveRecipeDialogState extends State<SaveRecipeDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text(RecipeCopy.save),
    content: ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        key: const Key('recipe_title_field'),
        controller: _controller,
        autofocus: true,
        maxLength: SaveRecipeDialog.maxTitleLength,
        decoration: const InputDecoration(hintText: RecipeCopy.recipeTitleHint),
        onSubmitted: _submit,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text(RecipeCopy.cancel),
      ),
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) => FilledButton(
          key: const Key('recipe_title_save_button'),
          // Disabled on an empty (or whitespace-only) trimmed title, the same
          // guard `_submit` re-applies for the Enter-key path.
          onPressed: value.text.trim().isEmpty
              ? null
              : () => _submit(value.text),
          child: const Text(RecipeCopy.save),
        ),
      ),
    ],
  );
}
