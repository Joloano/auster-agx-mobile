import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/roles.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_section_card.dart';
import '../providers/account_providers.dart';
import 'auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user != null && !_initialized) {
      _nameController.text = user.nome;
      _emailController.text = user.email;
      _initialized = true;
    }

    if (user == null) return const SizedBox.shrink();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          AusterPageHeader(
            icon: Icons.account_circle_rounded,
            title: 'Meu perfil',
            subtitle: perfilLabel(user.perfil),
          ),
          const SizedBox(height: 18),
          AusterSectionCard(
            title: 'Identidade',
            icon: Icons.badge_rounded,
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                    validator: (value) {
                      final required = _required(value);
                      if (required != null) return required;
                      return value!.contains('@') ? null : 'E-mail inválido';
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Senha atual para confirmar',
                      prefixIcon: const Icon(Icons.lock_rounded),
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
                    validator: _required,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? 'Salvando...' : 'Salvar perfil'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AusterSectionCard(
            title: 'Segurança',
            icon: Icons.security_rounded,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showChangePassword(context),
                icon: const Icon(Icons.password_rounded),
                label: const Text('Alterar senha'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = await ref.read(accountRepositoryProvider).updateMe(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            currentPassword: _currentPasswordController.text,
          );
      ref.read(authControllerProvider.notifier).applyUser(user);
      _currentPasswordController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showChangePassword(BuildContext context) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirmation = TextEditingController();
    final key = GlobalKey<FormState>();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Alterar senha'),
          content: Form(
            key: key,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha atual'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova senha'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmation,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirmar senha'),
                    validator: (value) =>
                        value == next.text ? null : 'As senhas não coincidem',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!key.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        await ref
                            .read(authControllerProvider.notifier)
                            .changePassword(
                              senhaAtual: current.text,
                              novaSenha: next.text,
                            );
                        if (!context.mounted || !mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Senha alterada com sucesso.'),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted || !mounted) return;
                        setDialogState(() => submitting = false);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                              content: Text(userFacingErrorMessage(error))),
                        );
                      }
                    },
              child: Text(submitting ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );

    current.dispose();
    next.dispose();
    confirmation.dispose();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFacingErrorMessage(error))),
    );
  }
}
