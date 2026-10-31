import 'package:flutter/material.dart';

import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/features/meal_plan/domain/meal_slot.dart';
import 'package:miga/features/meal_plan/presentation/meal_slot_presentation.dart';
import 'package:miga/l10n/app_localizations.dart';

/// A null result cancels; an empty string removes the existing meal.
Future<String?> showMealEditor(
  BuildContext context, {
  required DateTime date,
  required MealSlot slot,
  required String? meal,
  String? suggestion,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.cream,
    builder: (_) => _MealEditorSheet(
      date: date,
      slot: slot,
      meal: meal,
      suggestion: suggestion,
    ),
  );
}

class _MealEditorSheet extends StatefulWidget {
  const _MealEditorSheet({
    required this.date,
    required this.slot,
    required this.meal,
    required this.suggestion,
  });

  final DateTime date;
  final MealSlot slot;
  final String? meal;
  final String? suggestion;

  @override
  State<_MealEditorSheet> createState() => _MealEditorSheetState();
}

class _MealEditorSheetState extends State<_MealEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.suggestion ?? widget.meal ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.slot.label(l10n),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                MaterialLocalizations.of(context).formatFullDate(widget.date),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _controller,
                autofocus: true,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.homeMealName,
                  hintText: l10n.homeMealHint,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? l10n.homeMealRequired
                    : null,
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.olive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: _submit,
                child: Text(l10n.homeSaveMeal),
              ),
              if (widget.meal != null)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(''),
                  child: Text(l10n.homeRemoveMeal),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
