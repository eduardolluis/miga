import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import 'auth_submit_button.dart';

class AuthEmailForm extends StatelessWidget {
  const AuthEmailForm({
    super.key,
    required this.controller,
    required this.busy,
    required this.availableWidth,
    required this.onSendCode,
    required this.onGoogleSignIn,
  });

  final TextEditingController controller;
  final bool busy;
  final double availableWidth;
  final VoidCallback onSendCode;
  final VoidCallback onGoogleSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showApple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFF2F2F2),
            side: const BorderSide(color: Color(0xFF747775)),
            foregroundColor: const Color(0xFF1F1F1F),
            disabledForegroundColor: const Color(0xFF8E918F),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: busy ? null : onGoogleSignIn,
          icon: SvgPicture.asset(
            'assets/google.svg',
            width: 20,
            height: 20,
            excludeFromSemantics: true,
          ),
          label: Text(l10n.continueWithGoogle),
        ),
        if (showApple) ...[
          const SizedBox(height: 12),
          // TODO: Implement Sign in with Apple.
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF242424),
              disabledForegroundColor: const Color(0xFFBDBDBD),
              side: const BorderSide(color: Color(0xFF747775)),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: busy
                ? null
                : () {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.appleSignInUnavailable),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
            icon: const Icon(Icons.apple),
            label: Text(l10n.continueWithApple),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF9BA197))),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: availableWidth * 0.6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.orWithEmail,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFEBEEE7)),
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFF9BA197))),
          ],
        ),
        const SizedBox(height: 24),
        TextFormField(
          key: const ValueKey('email'),
          cursorColor: Colors.white,
          controller: controller,
          enabled: !busy,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSendCode(),
          decoration: InputDecoration(
            hintText: 'hello@example.com',
            hintStyle: const TextStyle(color: Colors.white),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            if (email.isEmpty) {
              return l10n.emailRequired;
            }
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
              return l10n.emailInvalid;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        AuthSubmitButton(
          label: l10n.emailMeCode,
          onPressed: busy ? null : onSendCode,
        ),
      ],
    );
  }
}
