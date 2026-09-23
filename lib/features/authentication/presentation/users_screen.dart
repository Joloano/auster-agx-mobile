import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/roles.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/auth_user.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../providers/account_providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  bool _includeInactive = false;
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(managedUsersProvider(_includeInactive));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
            children: [
              AusterPageHeader(
                icon: Icons.manage_accounts_rounded,
                title: 'Usuários',
                subtitle: 'Contas e permissões de acesso',
                trailing: IconButton.filled(
                  tooltip: 'Adicionar usuário',
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.person_add_rounded),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar por nome ou e-mail',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar busca',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _search = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
                onChanged: (value) => setState(() => _search = value.trim()),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Exibir usuários inativos'),
                value: _includeInactive,
                onChanged: (value) => setState(() => _includeInactive = value),
              ),
              const SizedBox(height: 4),
              usersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => AusterErrorState(
                  message: userFacingErrorMessage(error),
                  onRetry: _refresh,
                ),
                data: (users) => _UsersList(
                  users: _filterUsers(users),
                  onAction: _handleAction,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar usuário',
        onPressed: () => _openForm(),
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  List<AuthUser> _filterUsers(List<AuthUser> users) {
    final normalized = _search.toLowerCase();
    if (normalized.isEmpty) return users;
    return users
        .where(
          (user) =>
              user.nome.toLowerCase().contains(normalized) ||
              user.email.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    ref.invalidate(managedUsersProvider(_includeInactive));
    await ref.read(managedUsersProvider(_includeInactive).future);
  }

  Future<void> _handleAction(AuthUser user, _UserAction action) async {
    switch (action) {
      case _UserAction.edit:
        await _openForm(user: user);
      case _UserAction.toggleActive:
        await _toggleActive(user);
      case _UserAction.resetPassword:
        await _resetPassword(user);
    }
  }

  Future<void> _openForm({AuthUser? user}) async {
    final form = await showDialog<_UserFormData>(
      context: context,
      builder: (context) => _UserFormDialog(user: user),
    );
    if (form == null) return;

    try {
      if (user == null) {
        final result = await ref.read(accountRepositoryProvider).createUser(
              name: form.name,
              email: form.email,
              profile: form.profile,
              password: form.password!,
              temporaryPassword: form.temporaryPassword,
            );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usuário criado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.user.email),
                const SizedBox(height: 10),
                const Text('Senha provisionada'),
                SelectableText(
                  result.provisionedPassword,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Concluir'),
              ),
            ],
          ),
        );
      } else {
        await ref.read(accountRepositoryProvider).updateUser(
              userId: user.userId,
              name: form.name,
              email: form.email,
              profile: form.profile,
            );
        if (!mounted) return;
        _showMessage('Usuário atualizado com sucesso.');
      }
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _toggleActive(AuthUser user) async {
    final verb = user.ativo ? 'desativar' : 'ativar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.ativo ? 'Desativar' : 'Ativar'} usuário'),
        content: Text('Deseja $verb a conta de ${user.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(user.ativo ? 'Desativar' : 'Ativar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(accountRepositoryProvider)
          .setUserActive(user.userId, active: !user.ativo);
      if (!mounted) return;
      _showMessage('Conta ${user.ativo ? 'desativada' : 'ativada'}.');
      await _refresh();
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _resetPassword(AuthUser user) async {
    final controller = TextEditingController();
    final password = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir senha'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Senha temporária',
            helperText: 'Deixe vazio para gerar automaticamente.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null) return;

    try {
      final result = await ref
          .read(accountRepositoryProvider)
          .resetUserPassword(user.userId, password: password);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Senha temporária'),
          content: SelectableText(result.password),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Concluir'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    _showMessage(userFacingErrorMessage(error));
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({required this.users, required this.onAction});

  final List<AuthUser> users;
  final Future<void> Function(AuthUser user, _UserAction action) onAction;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: Text('Nenhum usuário encontrado.')),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var index = 0; index < users.length; index++) ...[
            ListTile(
              leading: CircleAvatar(
                child: Text(users[index].nome.substring(0, 1).toUpperCase()),
              ),
              title: Text(users[index].nome),
              subtitle: Text(
                '${users[index].email}\n${perfilLabel(users[index].perfil)}',
              ),
              isThreeLine: true,
              enabled: users[index].ativo,
              trailing: PopupMenuButton<_UserAction>(
                tooltip: 'Ações do usuário',
                onSelected: (action) => onAction(users[index], action),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _UserAction.edit,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_rounded),
                      title: Text('Editar'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: _UserAction.resetPassword,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.password_rounded),
                      title: Text('Redefinir senha'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _UserAction.toggleActive,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        users[index].ativo
                            ? Icons.person_off_rounded
                            : Icons.person_rounded,
                      ),
                      title: Text(users[index].ativo ? 'Desativar' : 'Ativar'),
                    ),
                  ),
                ],
              ),
            ),
            if (index < users.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

enum _UserAction { edit, toggleActive, resetPassword }

class _UserFormData {
  const _UserFormData({
    required this.name,
    required this.email,
    required this.profile,
    required this.password,
    required this.temporaryPassword,
  });

  final String name;
  final String email;
  final String profile;
  final String? password;
  final bool temporaryPassword;
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.user});

  final AuthUser? user;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  late String _profile;
  bool _temporaryPassword = true;
  bool _obscure = true;

  bool get _creating => widget.user == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.nome ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _profile = widget.user?.perfil ?? perfilLabels.keys.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_creating ? 'Adicionar usuário' : 'Editar usuário'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: (value) {
                    final required = _required(value);
                    if (required != null) return required;
                    return value!.contains('@') ? null : 'E-mail inválido';
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _profile,
                  decoration: const InputDecoration(labelText: 'Perfil'),
                  isExpanded: true,
                  items: perfilLabels.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _profile = value!),
                ),
                if (_creating) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Senha inicial',
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Exigir troca no primeiro acesso'),
                    value: _temporaryPassword,
                    onChanged: (value) {
                      setState(() => _temporaryPassword = value);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _UserFormData(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profile: _profile,
        password: _creating ? _passwordController.text : null,
        temporaryPassword: _temporaryPassword,
      ),
    );
  }
}
