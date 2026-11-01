import 'package:flutter/material.dart';
import 'package:miga/features/profile/domain/household_preferences.dart';
import 'package:miga/features/recipes/domain/recipe_ingredient.dart';
import 'package:miga/l10n/app_localizations.dart';
import 'package:miga/core/region/supported_regions.dart';

Future<HouseholdPreferences?> showHouseholdPreferences(
  BuildContext context,
  HouseholdPreferences value,
) => showModalBottomSheet<HouseholdPreferences>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => _PreferencesSheet(value),
);

class _PreferencesSheet extends StatefulWidget {
  const _PreferencesSheet(this.value);
  final HouseholdPreferences value;
  @override
  State<_PreferencesSheet> createState() => _PreferencesSheetState();
}

class _PreferencesSheetState extends State<_PreferencesSheet> {
  late String _country = widget.value.country;
  late String _currency = widget.value.currency;
  late String _language = widget.value.language ?? 'system';
  late int _members = widget.value.members;
  late final _restrictions = {...widget.value.restrictions};
  late final _disliked = {...widget.value.disliked};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l.preferencesTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: _country,
            decoration: InputDecoration(labelText: l.countryLabel),
            items: [
              for (final region in SupportedRegions.all)
                DropdownMenuItem(value: region.countryCode, child: Text(region.name)),
            ],
            onChanged: (v) => setState(() {
              if (v == null) return;
              _country = v;
              _currency = SupportedRegions.forCountry(v).currencyCode;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('preferences-currency-$_currency'),
            initialValue: _currency,
            decoration: InputDecoration(labelText: l.currencyLabel),
            items: [
              for (final code in SupportedRegions.currencies)
                DropdownMenuItem(value: code, child: Text('$code · ${SupportedRegions.symbol(code)}')),
            ],
            onChanged: (v) => setState(() => _currency = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: InputDecoration(labelText: l.languageLabel),
            items: [
              DropdownMenuItem(value: 'system', child: Text(l.systemLanguage)),
              const DropdownMenuItem(value: 'es', child: Text('Español')),
              const DropdownMenuItem(value: 'en', child: Text('English')),
            ],
            onChanged: (v) => setState(() => _language = v!),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _members,
            decoration: InputDecoration(labelText: l.householdMembers),
            items: [
              for (var n = 1; n <= 12; n++)
                DropdownMenuItem(value: n, child: Text('$n')),
            ],
            onChanged: (v) => setState(() => _members = v!),
          ),
          const SizedBox(height: 24),
          Text(
            l.restrictionsTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(l.restrictionsNote),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final restriction in DietaryRestriction.values)
                FilterChip(
                  label: Text(switch (restriction) {
                    DietaryRestriction.vegetarian => l.vegetarian,
                    DietaryRestriction.vegan => l.vegan,
                    DietaryRestriction.dairyFree => l.dairyFree,
                    DietaryRestriction.glutenFree => l.glutenFree,
                    DietaryRestriction.nutFree => l.nutFree,
                    DietaryRestriction.eggFree => l.eggFree,
                    DietaryRestriction.fishFree => l.fishFree,
                  }),
                  selected: _restrictions.contains(restriction),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _restrictions.add(restriction);
                    } else {
                      _restrictions.remove(restriction);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l.dislikedFoods, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final ingredient in RecipeIngredient.values)
                FilterChip(
                  label: Text(ingredient.label(l.localeName)),
                  selected: _disliked.contains(ingredient),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _disliked.add(ingredient);
                    } else {
                      _disliked.remove(ingredient);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              HouseholdPreferences(
                country: _country,
                currency: _currency,
                language: _language == 'system' ? null : _language,
                members: _members,
                restrictions: _restrictions,
                disliked: _disliked,
              ),
            ),
            child: Text(l.homeSave),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
