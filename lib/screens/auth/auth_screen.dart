import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _isLogin = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 48),
              Text(
                _isLogin ? l10n.login : l10n.createAccount,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';

                  if (email.isEmpty) return l10n.emailRequired;

                  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailPattern.hasMatch(email)) return l10n.emailInvalid;

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final password = value ?? '';

                  if (password.isEmpty) return l10n.passwordRequired;
                  if (password.length < 8) return l10n.passwordMinLength;

                  return null;
                },
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return l10n.passwordMismatch;
                    }

                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  _formKey.currentState!.validate();
                },
                child: Text(_isLogin ? l10n.login : l10n.createAccount),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                  _formKey.currentState?.reset();
                  _passwordController.clear();
                },
                child: Text(_isLogin ? l10n.noAccount : l10n.haveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
