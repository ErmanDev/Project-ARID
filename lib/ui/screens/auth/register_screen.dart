import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../providers.dart';
import '../../../services/auth/auth_service.dart';
import 'auth_widgets.dart';

/// Staff registration. The account is pending until an admin verifies it on
/// the web dashboard, so this screen ends signed out and returns `true` to the
/// sign-in screen, which explains the wait.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _birthdayField = GlobalKey<FormFieldState<String>>();
  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _birthday = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  DateTime? _birthDate;
  bool _busy = false;
  bool _attempted = false;
  bool _hidePassword = true;
  String? _error;

  static final _dateLabel = DateFormat.yMMMMd();

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _middleName,
      _lastName,
      _birthday,
      _username,
      _password,
      _confirm,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// The latest birthday that is still [AuthService.minimumAge] today.
  DateTime get _latestBirthDate {
    final now = DateTime.now();
    return DateTime(now.year - AuthService.minimumAge, now.month, now.day);
  }

  Future<void> _pickBirthday() async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final latest = _latestBirthDate;
    final picked = await showDatePicker(
      context: context,
      helpText: 'Select your birthday',
      initialDate: _birthDate ?? DateTime(latest.year - 10, latest.month),
      firstDate: DateTime(1900),
      lastDate: latest,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _birthDate = picked;
      _birthday.text = _dateLabel.format(picked);
    });
    // Re-check only this field, so choosing a date does not flag the
    // fields the person has not reached yet.
    _birthdayField.currentState?.validate();
  }

  String? _birthdayProblem(String? _) {
    final date = _birthDate;
    if (date == null) return 'Select your birthday.';
    if (AuthService.ageOn(date, DateTime.now()) < AuthService.minimumAge) {
      return 'You must be at least ${AuthService.minimumAge} years old.';
    }
    return null;
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
            firstName: _firstName.text,
            middleName: _middleName.text,
            lastName: _lastName.text,
            birthDate: _birthDate!,
            username: _username.text,
            password: _password.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthFailure catch (failure) {
      if (mounted) setState(() => _error = failure.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Couldn’t submit your registration. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBack: true,
      content: [
        const AuthHeading(
          title: 'Create an account',
          subtitle:
              'Register as A.R.I.D. staff. An admin will verify your account '
              'before you can sign in.',
        ),
        const SizedBox(height: 28),
        Form(
          key: _form,
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
                const AuthSectionLabel('Your details'),
                TextFormField(
                  controller: _firstName,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'First name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: (value) =>
                      _required(value, 'Enter your first name.'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _middleName,
                  enabled: !_busy,
                  decoration: const InputDecoration(
                    labelText: 'Middle name (optional)',
                  ),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.middleName],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _lastName,
                  enabled: !_busy,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.familyName],
                  validator: (value) =>
                      _required(value, 'Enter your last name.'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: _birthdayField,
                  controller: _birthday,
                  enabled: !_busy,
                  readOnly: true,
                  onTap: _pickBirthday,
                  decoration: const InputDecoration(
                    labelText: 'Birthday',
                    helperText:
                        'You must be at least ${AuthService.minimumAge} years '
                        'old.',
                    suffixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  validator: _birthdayProblem,
                ),
                const SizedBox(height: 24),
                const AuthSectionLabel('Sign-in details'),
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
          child: Text(_busy ? 'Submitting…' : 'Create account'),
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
