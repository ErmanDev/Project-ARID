import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../services/auth/auth_service.dart';
import '../../widgets/arid_logo.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

/// Username and password sign-in, the same accounts as the web dashboard.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _attempted = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _attempted = true);
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // authUserProvider switches the app to the main screens on success.
      await ref
          .read(authServiceProvider)
          .signIn(_username.text, _password.text);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Couldn’t sign in. Try again in a moment.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      content: [
        const Center(child: AridLogo(size: 80)),
        const SizedBox(height: 20),
        const AuthHeading(
          title: 'Sign in to A.R.I.D.',
          subtitle:
              'Use your username and password. New here? Create a field '
              'reporter account.',
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
                  controller: _username,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'Username'),
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter your username.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: PasswordVisibilityButton(
                      hidden: _hidePassword,
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _signIn(),
                  validator: (value) =>
                      (value ?? '').isEmpty ? 'Enter your password.' : null,
                ),
              ],
            ),
          ),
        ),
      ],
      actions: [
        FilledButton(
          onPressed: _busy ? null : _signIn,
          child: Text(_busy ? 'Signing in…' : 'Sign in'),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _busy
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
          child: const Text('Create an account'),
        ),
      ],
    );
  }
}
