import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../services/auth/auth_service.dart';
import 'auth_widgets.dart';

/// Creates a field reporter account. Mobile sign-ups are always field
/// reporters and are verified right away; admins register on the dashboard.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _attempted = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy) return;
    setState(() => _attempted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .register(
            displayName: _name.text.trim(),
            username: _username.text,
            password: _password.text,
          );
      // The app switches to the main screens underneath; leave this route.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Couldn’t create your account. Try again in a moment.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      content: [
        const AuthHeading(
          title: 'Create an account',
          subtitle:
              'You’ll join as a field reporter and can start reporting right '
              'away.',
        ),
        const SizedBox(height: 28),
        Form(
          key: _form,
          // Errors clear as soon as a field is fixed, once a submit has shown
          // them.
          autovalidateMode: _attempted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[
                  AuthError(message: _error!),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Enter your full name.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _username,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    helperText: 'Letters, numbers, dots, dashes, or underscores.',
                  ),
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newUsername],
                  validator: (value) =>
                      AuthService.usernameProblem(value ?? ''),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText:
                        'At least ${AuthService.minPasswordLength} characters.',
                    suffixIcon: PasswordVisibilityButton(
                      hidden: _hidePassword,
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) =>
                      (value ?? '').length < AuthService.minPasswordLength
                      ? 'Use at least ${AuthService.minPasswordLength} '
                            'characters.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  enabled: !_busy,
                  obscureText: _hidePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (value) => value != _password.text
                      ? 'The passwords do not match.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
      actions: [
        FilledButton(
          onPressed: _busy ? null : _register,
          child: Text(_busy ? 'Creating account…' : 'Create account'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('I already have an account'),
        ),
      ],
    );
  }
}
