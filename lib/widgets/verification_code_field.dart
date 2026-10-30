import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One accessible input preserves paste, autofill, and backspace across digits.
class VerificationCodeField extends StatefulWidget {
  const VerificationCodeField({
    super.key,
    required this.controller,
    required this.label,
    required this.errorText,
    required this.onSubmitted,
    this.enabled = true,
    this.hasError = false,
    this.errorCount = 0,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String errorText;
  final VoidCallback onSubmitted;
  final bool enabled;
  final bool hasError;
  final int errorCount;
  final ValueChanged<String>? onChanged;

  @override
  State<VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<VerificationCodeField> {
  static const _codeLength = 6;
  static const _errorColor = Color(0xFFFF6B6B);
  final _focusNode = FocusNode();
  static final _shake = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
  ]);

  Future<void> _showPasteMenu(Offset position) async {
    if (!widget.enabled) return;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final localPosition = overlay.globalToLocal(position);
    final paste = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromRect(
        localPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: true,
          child: Text(MaterialLocalizations.of(context).pasteButtonLabel),
        ),
      ],
    );
    if (paste != true || !mounted || !widget.enabled) return;
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || !widget.enabled || clipboard?.text == null) return;
    final digits = clipboard!.text!.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final code = digits.substring(0, digits.length.clamp(0, _codeLength));
    widget.controller.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    _focusInput();
    _onChanged(code);
  }

  void _onChanged(String value) {
    widget.onChanged?.call(value);
  }

  void _focusInput() {
    if (!widget.enabled) return;
    widget.controller.selection = TextSelection.collapsed(
      offset: widget.controller.text.length,
    );
    if (_focusNode.hasFocus) {
      // Tapping another box must also reopen a dismissed keyboard when the
      // input still holds focus.
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animateError =
        widget.hasError && !MediaQuery.disableAnimationsOf(context);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, _focusNode]),
      builder: (context, _) {
        final value = widget.controller.text;
        final selected = widget.controller.selection.extentOffset.clamp(
          0,
          _codeLength - 1,
        );
        return Semantics(
          label: widget.label,
          child: Stack(
            children: [
              TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent, fontSize: 24),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                    _codeLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  ),
                ],
                textInputAction: TextInputAction.done,
                onChanged: _onChanged,
                onFieldSubmitted: (_) => widget.onSubmitted(),
                decoration: InputDecoration(
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  errorMaxLines: 3,
                  errorStyle: const TextStyle(
                    color: _errorColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    height: 1.5,
                  ),
                ),
                validator: (value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
                    ? null
                    : widget.errorText,
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 60,
                child: ExcludeSemantics(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey((animateError, widget.errorCount)),
                    tween: Tween(begin: 0, end: animateError ? 1 : 0),
                    duration: animateError
                        ? const Duration(milliseconds: 360)
                        : Duration.zero,
                    builder: (context, progress, child) => Transform.translate(
                      key: const ValueKey('code-feedback'),
                      offset: Offset(_shake.transform(progress), 0),
                      child: child,
                    ),
                    child: Row(
                      textDirection: TextDirection.ltr,
                      spacing: 8,
                      children: List.generate(_codeLength, (index) {
                        final active =
                            widget.enabled &&
                            _focusNode.hasFocus &&
                            index == selected;
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _focusInput,
                            onLongPressStart: (details) =>
                                _showPasteMenu(details.globalPosition),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xD9202A1F),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.hasError
                                      ? _errorColor
                                      : active
                                      ? Colors.white
                                      : Colors.white60,
                                  width: widget.hasError || active ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                index < value.length ? value[index] : '–',
                                style: TextStyle(
                                  color: widget.enabled
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                                textScaler: TextScaler.noScaling,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
