import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/user_facing_error.dart';
import 'auth_controller.dart';
import 'widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue && next.value != null && mounted) {
        context.go(
          next.value!.deveAlterarSenha ? '/change-password' : '/dashboard',
        );
      }
    });

    return AuthShell(
      title: 'ACESSAR PLATAFORMA',
      subtitle: 'Acompanhe as demandas do AusterAgX onde estiver.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: authFieldDecoration(
                  hint: 'E-mail',
                  icon: Icons.email_rounded,
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe o e-mail' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _senhaController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => auth.isLoading ? null : _submit(),
                autofillHints: const [AutofillHints.password],
                decoration: authFieldDecoration(
                  hint: 'Senha',
                  icon: Icons.lock_rounded,
                  suffixIcon: IconButton(
                    tooltip:
                        _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Informe a senha' : null,
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                style: authPrimaryButtonStyle(),
                onPressed: auth.isLoading ? null : _submit,
                icon: auth.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login_rounded),
                label: Text(auth.isLoading ? 'Entrando...' : 'Entrar'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.isLoading
                      ? null
                      : () => context.go('/esqueci-senha'),
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              if (auth.hasError) ...[
                const SizedBox(height: 16),
                AuthErrorMessage(
                  userFacingErrorMessage(auth.error!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text.trim(), _senhaController.text);
  }
}
