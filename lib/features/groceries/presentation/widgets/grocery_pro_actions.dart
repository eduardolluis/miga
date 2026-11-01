import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';
import 'package:miga/l10n/app_localizations.dart';

class GroceryProActions extends StatefulWidget {
  const GroceryProActions({
    super.key,
    required this.isPro,
    this.onGenerate,
    this.onCompare,
    this.onUpgrade,
  });
  final bool isPro;
  final Future<void> Function()? onGenerate, onCompare;
  final VoidCallback? onUpgrade;
  @override
  State<GroceryProActions> createState() => _GroceryProActionsState();
}

class _GroceryProActionsState extends State<GroceryProActions> {
  String? _busy;
  Future<void> _run(String action, Future<void> Function()? callback) async {
    if (_busy != null) return;
    if (!widget.isPro) {
      widget.onUpgrade?.call();
      return;
    }
    if (callback == null) return;
    setState(() => _busy = action);
    try {
      await callback();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.homeSaveError)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        _action(
          'generate',
          Icons.auto_awesome_outlined,
          l.groceryGenerateFromPlan,
          widget.onGenerate,
        ),
        const SizedBox(height: 8),
        _action(
          'compare',
          Icons.compare_arrows_rounded,
          l.storeCompare,
          widget.onCompare,
        ),
      ],
    );
  }

  Widget _action(
    String id,
    IconData icon,
    String title,
    Future<void> Function()? callback,
  ) => Material(
    color: const Color(0xFFFEFDF9),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: AppColors.line),
      borderRadius: BorderRadius.circular(18),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: ValueKey('grocery-pro-$id'),
      onTap: _busy != null || (widget.isPro && callback == null)
          ? null
          : () => _run(id, callback),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            if (_busy == id && ModalRoute.of(context)?.isCurrent != false)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(icon, size: 22, color: AppColors.olive),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (!widget.isPro)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3A0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Color(0xFF785113),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.muted,
              ),
          ],
        ),
      ),
    ),
  );
}
