import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/auth_user.dart';
import '../../../data/models/page_response.dart';
import '../../../data/models/system_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../authentication/providers/account_providers.dart';
import '../providers/system_providers.dart';

class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  late Future<_AuditData> _future;
  List<String>? _entities;
  List<AuthUser>? _users;
  _AuditView _view = _AuditView.records;
  String? _entity;
  String? _entityId;
  String? _userId;
  String? _action;
  late final String _defaultFrom;
  late final String _defaultTo;
  late String? _from;
  late String? _to;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _defaultFrom = _apiDate(today.subtract(const Duration(days: 30)));
    _defaultTo = _apiDate(today);
    _from = _defaultFrom;
    _to = _defaultTo;
    _future = _load();
  }

  Future<_AuditData> _load() async {
    final api = ref.read(systemApiProvider);
    final pageRequest = api.listAudit(
      entity: _entity,
      entityId: _entityId,
      userId: _userId,
      action: _action,
      from: _from,
      to: _to,
      page: _page,
    );
    final entitiesRequest = _entities == null
        ? api.listAuditedEntities()
        : Future.value(_entities!);
    final usersRequest = _users == null
        ? ref
            .read(accountRepositoryProvider)
            .listUsers(includeInactive: true)
            .catchError((_) => <AuthUser>[])
        : Future.value(_users!);

    final page = await pageRequest;
    _entities = await entitiesRequest;
    _users = await usersRequest;
    return _AuditData(
      page: page,
      entities: _entities!,
      users: _users!,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
            children: [
              AusterPageHeader(
                icon: Icons.fact_check_rounded,
                title: 'Auditoria',
                subtitle: 'Histórico de alterações dos registros',
                trailing: IconButton.filledTonal(
                  tooltip: 'Exportar página em CSV',
                  onPressed: _exportCurrentPage,
                  icon: const Icon(Icons.download_rounded),
                ),
              ),
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<_AuditView>(
                  segments: const [
                    ButtonSegment(
                      value: _AuditView.records,
                      icon: Icon(Icons.table_rows_rounded),
                      label: Text('Registros'),
                    ),
                    ButtonSegment(
                      value: _AuditView.users,
                      icon: Icon(Icons.person_search_rounded),
                      label: Text('Por usuário'),
                    ),
                    ButtonSegment(
                      value: _AuditView.timeline,
                      icon: Icon(Icons.timeline_rounded),
                      label: Text('Timeline'),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (selection) {
                    setState(() => _view = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _openFilters,
                    icon: const Icon(Icons.filter_alt_rounded),
                    label: const Text('Filtros'),
                  ),
                  const SizedBox(width: 8),
                  if (_hasFilters)
                    IconButton(
                      tooltip: 'Limpar filtros',
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off_rounded),
                    ),
                  const Spacer(),
                  if (_hasFilters)
                    Chip(
                      avatar: const Icon(Icons.check_rounded, size: 16),
                      label: Text(_filterLabel),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<_AuditData>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return AusterErrorState(
                      message: userFacingErrorMessage(snapshot.error!),
                      onRetry: _refresh,
                    );
                  }
                  return _content(snapshot.data!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasFilters => [
        _entity,
        _entityId,
        _userId,
        _action,
        _from,
        _to,
      ].any((value) => value != null && value.isNotEmpty);

  String get _filterLabel {
    final onlyDefaultWindow = _entity == null &&
        _entityId == null &&
        _userId == null &&
        _action == null &&
        _from == _defaultFrom &&
        _to == _defaultTo;
    return onlyDefaultWindow ? 'Últimos 30 dias' : 'Filtrado';
  }

  Widget _content(_AuditData data) {
    final page = data.page;
    if (page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Nenhum evento de auditoria encontrado.')),
      );
    }

    return Column(
      children: [
        switch (_view) {
          _AuditView.records => _records(page.items),
          _AuditView.users => _byUser(page.items),
          _AuditView.timeline => _timeline(page.items),
        },
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${page.totalItems} eventos · página ${page.page + 1} de ${page.totalPages == 0 ? 1 : page.totalPages}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            IconButton(
              tooltip: 'Página anterior',
              onPressed: page.hasPreviousPage ? () => _changePage(-1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            IconButton(
              tooltip: 'Próxima página',
              onPressed: page.hasNextPage ? () => _changePage(1) : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Widget _records(List<AuditEntry> entries) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          _auditTile(entries[index]),
          if (index < entries.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _byUser(List<AuditEntry> entries) {
    final groups = <String, List<AuditEntry>>{};
    for (final entry in entries) {
      groups
          .putIfAbsent(
            entry.userName.isEmpty ? 'Sistema' : entry.userName,
            () => [],
          )
          .add(entry);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    group.key,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text('${group.value.length}'),
              ],
            ),
          ),
          for (final entry in group.value) ...[
            _auditTile(entry, showUser: false),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _timeline(List<AuditEntry> entries) {
    final groups = <String, List<AuditEntry>>{};
    for (final entry in entries) {
      groups.putIfAbsent(_date(entry.createdAt), () => []).add(entry);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(
              group.key,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          for (final entry in group.value)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 36,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _actionColor(entry.action),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AusterColors.neutral200,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _auditTile(entry),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _auditTile(AuditEntry entry, {bool showUser = true}) {
    final changes = _changedFields(entry);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AusterColors.neutral200),
      ),
      child: ListTile(
        minTileHeight: 76,
        leading: CircleAvatar(
          backgroundColor: _actionColor(entry.action).withValues(alpha: 0.12),
          foregroundColor: _actionColor(entry.action),
          child: Icon(_actionIcon(entry.action)),
        ),
        title: Text(
          '${_actionLabel(entry.action)} ${_entityLabel(entry.entity)}',
        ),
        subtitle: Text(
          [
            if (showUser) entry.userName.isEmpty ? 'Sistema' : entry.userName,
            _dateTime(entry.createdAt),
            if (changes.isNotEmpty) changes.join(', '),
          ].join(' · '),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showDetails(entry),
      ),
    );
  }

  Future<void> _openFilters() async {
    final data = await _future;
    if (!mounted) return;
    final values = await showAusterRecordForm(
      context: context,
      title: 'Filtrar auditoria',
      submitLabel: 'Aplicar',
      fields: [
        RecordFieldSpec(
          key: 'entidade',
          label: 'Entidade',
          kind: RecordFieldKind.choice,
          options: [
            const RecordFieldOption(value: '', label: 'Todas'),
            ...data.entities.map(
              (entity) => RecordFieldOption(
                value: entity,
                label: _entityLabel(entity),
              ),
            ),
          ],
        ),
        const RecordFieldSpec(
          key: 'entidadeId',
          label: 'ID do registro',
        ),
        RecordFieldSpec(
          key: 'usuarioId',
          label: 'Usuário',
          kind: RecordFieldKind.choice,
          options: [
            const RecordFieldOption(value: '', label: 'Todos'),
            ...data.users.map(
              (user) => RecordFieldOption(
                value: user.userId,
                label: user.nome,
              ),
            ),
          ],
        ),
        const RecordFieldSpec(
          key: 'acao',
          label: 'Ação',
          kind: RecordFieldKind.choice,
          options: [
            RecordFieldOption(value: '', label: 'Todas'),
            RecordFieldOption(value: 'CREATE', label: 'Criação'),
            RecordFieldOption(value: 'UPDATE', label: 'Alteração'),
            RecordFieldOption(value: 'DELETE', label: 'Exclusão'),
          ],
        ),
        const RecordFieldSpec(
          key: 'de',
          label: 'Data inicial',
          kind: RecordFieldKind.date,
        ),
        const RecordFieldSpec(
          key: 'ate',
          label: 'Data final',
          kind: RecordFieldKind.date,
        ),
      ],
      initialValues: {
        'entidade': _entity ?? '',
        'entidadeId': _entityId,
        'usuarioId': _userId ?? '',
        'acao': _action ?? '',
        'de': _from,
        'ate': _to,
      },
    );
    if (values == null) return;
    final entity = _text(values['entidade']);
    final entityId = _text(values['entidadeId']);
    final userId = _text(values['usuarioId']);
    final action = _text(values['acao']);
    var from = _text(values['de']);
    var to = _text(values['ate']);
    if (entityId != null && entity == null) {
      _showMessage('Selecione a entidade para filtrar pelo ID do registro.');
      return;
    }
    if (from != null && to != null && from.compareTo(to) > 0) {
      _showMessage('A data inicial deve ser anterior à data final.');
      return;
    }
    if (entity == null && userId == null && from == null && to == null) {
      from = _defaultFrom;
      to = _defaultTo;
    }
    setState(() {
      _entity = entity;
      _entityId = entityId;
      _userId = userId;
      _action = action;
      _from = from;
      _to = to;
      _page = 0;
      _future = _load();
    });
  }

  void _clearFilters() {
    setState(() {
      _entity = null;
      _entityId = null;
      _userId = null;
      _action = null;
      _from = _defaultFrom;
      _to = _defaultTo;
      _page = 0;
      _future = _load();
    });
  }

  void _changePage(int delta) {
    setState(() {
      _page += delta;
      _future = _load();
    });
  }

  Future<void> _exportCurrentPage() async {
    try {
      final data = await _future;
      if (data.page.items.isEmpty) {
        if (mounted) _showMessage('Não há eventos nesta página para exportar.');
        return;
      }
      final csv = _auditCsv(data.page.items);
      final bytes = Uint8List.fromList([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(csv),
      ]);
      final path = await FilePicker.saveFile(
        dialogTitle: 'Exportar auditoria',
        fileName:
            'auditoria-${DateTime.now().toIso8601String().split('T').first}.csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: bytes,
      );
      if (!mounted) return;
      _showMessage(
          path == null ? 'Exportação concluída.' : 'CSV salvo em $path');
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _showDetails(AuditEntry entry) {
    const encoder = JsonEncoder.withIndent('  ');
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('${_actionLabel(entry.action)} ${_entityLabel(entry.entity)}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuditDetail(label: 'Registro', value: entry.entityId),
                _AuditDetail(
                  label: 'Autor',
                  value: entry.userName.isEmpty ? 'Sistema' : entry.userName,
                ),
                _AuditDetail(
                  label: 'Data e hora',
                  value: _dateTime(entry.createdAt),
                ),
                const SizedBox(height: 12),
                Text('Valores anteriores',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                SelectableText(
                  entry.oldValues == null
                      ? '-'
                      : encoder.convert(entry.oldValues),
                ),
                const SizedBox(height: 16),
                Text('Novos valores',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                SelectableText(
                  entry.newValues == null
                      ? '-'
                      : encoder.convert(entry.newValues),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AuditData {
  const _AuditData({
    required this.page,
    required this.entities,
    required this.users,
  });

  final PageResponse<AuditEntry> page;
  final List<String> entities;
  final List<AuthUser> users;
}

class _AuditDetail extends StatelessWidget {
  const _AuditDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

enum _AuditView { records, users, timeline }

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String _apiDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _actionLabel(String action) {
  return switch (action) {
    'CREATE' => 'Criou',
    'UPDATE' => 'Alterou',
    'DELETE' => 'Excluiu',
    _ => action,
  };
}

IconData _actionIcon(String action) {
  return switch (action) {
    'CREATE' => Icons.add_rounded,
    'UPDATE' => Icons.edit_rounded,
    'DELETE' => Icons.delete_outline_rounded,
    _ => Icons.history_rounded,
  };
}

Color _actionColor(String action) {
  return switch (action) {
    'CREATE' => AusterColors.success,
    'UPDATE' => AusterColors.info,
    'DELETE' => AusterColors.error,
    _ => AusterColors.neutral700,
  };
}

String _entityLabel(String entity) {
  const labels = {
    'Talhao': 'Talhão',
    'Usuario': 'Usuário',
    'Demanda': 'Demanda',
    'Pedido': 'Pedido',
    'Cultura': 'Cultura',
    'Fazenda': 'Fazenda',
    'Cliente': 'Cliente',
    'Colaborador': 'Colaborador',
    'Cultivo': 'Cultivo',
    'Equipamento': 'Equipamento',
    'Grupo': 'Grupo',
    'PrescricaoSmartBrake': 'Prescrição Smart-Brake',
    'PrescricaoSmartSeeding': 'Prescrição Smart-Seeding',
    'ManejoNitrogenio': 'Manejo de nitrogênio',
    'SensoriamentoRemoto': 'Sensoriamento remoto',
    'CulturaAntecessora': 'Cultura antecessora',
    'DadosSolo': 'Dados de solo',
    'EstadioFenologico': 'Estádio fenológico',
    'ClienteFazenda': 'Vínculo cliente-fazenda',
    'ArquivoUpload': 'Upload de arquivo',
  };
  return labels[entity] ??
      entity.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      );
}

List<String> _changedFields(AuditEntry entry) {
  return {
    ...?entry.oldValues?.keys,
    ...?entry.newValues?.keys,
  }.toList()
    ..sort();
}

String _date(String iso) {
  final value = DateTime.tryParse(iso)?.toLocal();
  if (value == null) return iso;
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _dateTime(String iso) {
  final value = DateTime.tryParse(iso)?.toLocal();
  if (value == null) return iso;
  return '${_date(value.toIso8601String())} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

String _auditCsv(List<AuditEntry> entries) {
  String escape(Object? value) {
    final text = value?.toString().replaceAll('"', '""') ?? '';
    return '"$text"';
  }

  final rows = <String>[
    ['Data/Hora', 'Autor', 'Entidade', 'ID do Registro', 'Ação', 'Campos']
        .map(escape)
        .join(';'),
    for (final entry in entries)
      [
        _dateTime(entry.createdAt),
        entry.userName,
        _entityLabel(entry.entity),
        entry.entityId,
        _actionLabel(entry.action),
        _changedFields(entry).join(', '),
      ].map(escape).join(';'),
  ];
  return rows.join('\r\n');
}
