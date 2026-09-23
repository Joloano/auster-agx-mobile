import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import '../providers/account_providers.dart';
import 'widgets/auth_shell.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({this.initialToken, super.key});

  final String? initialToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'DEFINIR NOVA SENHA',
      subtitle: 'Use o token recebido por e-mail e escolha uma nova senha.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if ((widget.initialToken ?? '').isEmpty) ...[
              TextFormField(
                controller: _tokenController,
                decoration: authFieldDecoration(
                  hint: 'Token de redefinição',
                  icon: Icons.key_rounded,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o token'
                    : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: authFieldDecoration(
                hint: 'Nova senha',
                icon: Icons.lock_rounded,
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Informe a nova senha'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmationController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              decoration: authFieldDecoration(
                hint: 'Confirmar nova senha',
                icon: Icons.lock_reset_rounded,
              ),
              validator: (value) => value != _passwordController.text
                  ? 'As senhas não coincidem'
                  : null,
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
                  : const Icon(Icons.password_rounded),
              label: Text(_submitting ? 'Salvando...' : 'Redefinir senha'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              AuthErrorMessage(_error!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).resetPassword(
            token: _tokenController.text.trim(),
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha redefinida com sucesso.')),
      );
      context.go('/login');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userFacingErrorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
