import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/home_details.dart';
import '../../theme/app_colors.dart';

Future<WeeklyBudget?> showBudgetEditor(
  BuildContext context,
  WeeklyBudget? budget,
) => showModalBottomSheet<WeeklyBudget>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.cream,
  builder: (_) => _BudgetEditor(budget: budget),
);

class _BudgetEditor extends StatefulWidget {
  const _BudgetEditor({required this.budget});
  final WeeklyBudget? budget;

  @override
  State<_BudgetEditor> createState() => _BudgetEditorState();
}

class _BudgetEditorState extends State<_BudgetEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _limit = TextEditingController(
    text: widget.budget?.limit.toString() ?? '',
  );
  late final _spent = TextEditingController(
    text: widget.budget?.spent.toString() ?? '0',
  );
  late String _currency = widget.budget?.currency ?? 'DOP';

  @override
  void dispose() {
    _limit.dispose();
    _spent.dispose();
    super.dispose();
  }

  double? _amount(String? text) =>
      double.tryParse((text ?? '').replaceAll(',', '.'));

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
                l10n.homeBudget,
                style: const TextStyle(
                  fontFamily: 'LiberationSerif',
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 24),
              for (final isLimit in [true, false]) ...[
                TextFormField(
                  key: ValueKey(isLimit ? 'budget-limit' : 'budget-spent'),
                  controller: isLimit ? _limit : _spent,
                  maxLength: 12,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: isLimit
                        ? l10n.homeBudgetLimit
                        : l10n.homeBudgetSpent,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (text) {
                    final amount = _amount(text);
                    return amount == null ||
                            !amount.isFinite ||
                            amount > 1000000000 ||
                            (isLimit ? amount <= 0 : amount < 0)
                        ? l10n.homeBudgetValidation
                        : null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: InputDecoration(
                  labelText: l10n.homeCurrency,
                  border: const OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'DOP', child: Text('DOP · RD\$')),
                  DropdownMenuItem(value: 'USD', child: Text('USD · \$')),
                ],
                onChanged: (value) => _currency = value!,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).pop(
                      WeeklyBudget(
                        limit: _amount(_limit.text)!,
                        spent: _amount(_spent.text)!,
                        currency: _currency,
                      ),
                    );
                  }
                },
                child: Text(l10n.homeSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
