import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/verification_code_field.dart';
import 'auth_submit_button.dart';

class AuthCodeForm extends StatelessWidget {
  const AuthCodeForm({
    super.key,
    required this.controller,
    required this.busy,
    required this.hasError,
    required this.errorCount,
    required this.resendSeconds,
    required this.onChanged,
    required this.onVerify,
    required this.onResend,
    required this.onChangeEmail,
  });

  final TextEditingController controller;
  final bool busy;
  final bool hasError;
  final int errorCount;
  final int resendSeconds;
  final ValueChanged<String> onChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canResend = !busy && resendSeconds == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VerificationCodeField(
          key: const ValueKey('code'),
          controller: controller,
          enabled: !busy,
          label: l10n.emailCode,
          errorText: l10n.codeRequired,
          hasError: hasError,
          errorCount: errorCount,
          onChanged: onChanged,
          onSubmitted: onVerify,
        ),
        const SizedBox(height: 20),
        AuthSubmitButton(
          label: l10n.verifyCode,
          onPressed: busy ? null : onVerify,
        ),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white54,
            textStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              decoration: canResend
                  ? TextDecoration.underline
                  : TextDecoration.none,
            ),
          ),
          onPressed: canResend ? onResend : null,
          child: Text(
            resendSeconds > 0 ? l10n.resendIn(resendSeconds) : l10n.resendCode,
          ),
        ),
        TextButton(
          onPressed: busy ? null : onChangeEmail,
          child: Text(l10n.changeEmail),
        ),
      ],
    );
  }
}
