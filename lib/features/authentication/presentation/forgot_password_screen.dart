import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../providers/account_providers.dart';
import 'widgets/auth_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'RECUPERAR SENHA',
      subtitle: 'Informe o e-mail da conta para receber as orientações.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: authFieldDecoration(
                hint: 'E-mail',
                icon: Icons.email_rounded,
              ),
              validator: _validateEmail,
              onFieldSubmitted: (_) => _submitting ? null : _submit(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: authPrimaryButtonStyle(),
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.mark_email_read_rounded),
              label: Text(_submitting ? 'Enviando...' : 'Enviar instruções'),
            ),
            TextButton.icon(
              onPressed: _submitting ? null : () => context.go('/login'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar ao login'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthErrorMessage(_error!),
            ],
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe o e-mail';
    if (!email.contains('@')) return 'Informe um e-mail válido';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _message = null;
      _error = null;
    });
    try {
      await ref
          .read(accountRepositoryProvider)
          .forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _message =
            'Se o e-mail estiver cadastrado, as instruções serão enviadas.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userFacingErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
