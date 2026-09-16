import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';
import 'widgets/auth_shell.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _novaSenhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _submitting = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmation = true;
  String? _error;

  @override
  void dispose() {
    _novaSenhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;

    return AuthShell(
      title: 'TROCA DE SENHA',
      subtitle: user == null
          ? 'Defina uma nova senha para continuar.'
          : 'Senha provisória detectada para ${user.email}.',
      action: IconButton(
        tooltip: 'Sair',
        onPressed: _submitting
            ? null
            : () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
        icon: const Icon(Icons.logout_rounded),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _novaSenhaController,
                obscureText: _obscureNewPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: authFieldDecoration(
                  hint: 'Nova senha',
                  icon: Icons.lock_reset_rounded,
                  suffixIcon: IconButton(
                    tooltip:
                        _obscureNewPassword ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe a nova senha';
                  }
                  if (value.length < 6) {
                    return 'Use pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 6),
                child: Text(
                  'Mínimo de 6 caracteres',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmacaoController,
                obscureText: _obscureConfirmation,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitting ? null : _submit(),
                autofillHints: const [AutofillHints.newPassword],
                decoration: authFieldDecoration(
                  hint: 'Confirmar senha',
                  icon: Icons.verified_user_rounded,
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmation
                        ? 'Mostrar confirmação'
                        : 'Ocultar confirmação',
                    onPressed: () {
                      setState(() {
                        _obscureConfirmation = !_obscureConfirmation;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirme a nova senha';
                  }
                  if (value != _novaSenhaController.text) {
                    return 'As senhas não conferem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 22),
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
                    : const Icon(Icons.check_rounded),
                label: Text(_submitting ? 'Alterando...' : 'Alterar senha'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorMessage(_error!),
              ],
            ],
          ),
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
      await ref.read(authControllerProvider.notifier).changePassword(
            novaSenha: _novaSenhaController.text,
          );
      if (mounted) context.go('/dashboard');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível alterar a senha.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}
