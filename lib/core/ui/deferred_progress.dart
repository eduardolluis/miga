import 'dart:async';

import 'package:flutter/material.dart';
import 'package:miga/core/theme/app_colors.dart';

class DeferredProgress extends StatefulWidget {
  const DeferredProgress({super.key, required this.active});
  final bool active;
  @override
  State<DeferredProgress> createState() => _DeferredProgressState();
}

class _DeferredProgressState extends State<DeferredProgress> {
  Timer? _timer;
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void didUpdateWidget(DeferredProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) _update();
  }

  void _update() {
    _timer?.cancel();
    if (!widget.active) {
      _visible = false;
      return;
    }
    _timer = Timer(const Duration(milliseconds: 140), () {
      if (mounted && widget.active) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _visible
      ? const LinearProgressIndicator(
          minHeight: 2,
          color: AppColors.olive,
          backgroundColor: Colors.transparent,
        )
      : const SizedBox.shrink();
}
