import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_theme.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../data/models/page_response.dart';
import '../../../data/models/system_models.dart';
import '../../../widgets/auster_error_state.dart';
import '../../../widgets/auster_page_header.dart';
import '../../../widgets/auster_record_form.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../modules/domain/module_access.dart';
import '../providers/system_providers.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen>
    with WidgetsBindingObserver {
  late Future<PageResponse<FeedbackReport>> _future;
  String? _type;
  _FeedbackStatus _status = _FeedbackStatus.all;
  int _page = 0;
  bool? _driveConnected;
  bool _checkingDrive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _load();
    _checkDrive();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkDrive();
  }

  Future<PageResponse<FeedbackReport>> _load() {
    return ref.read(systemApiProvider).listFeedback(
          type: _type,
          pending: _status == _FeedbackStatus.pending ? true : null,
          discardedOnly: _status == _FeedbackStatus.discarded ? true : null,
          page: _page,
        );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _checkDrive() async {
    if (_checkingDrive) return;
    _checkingDrive = true;
    try {
      final connected =
          await ref.read(systemApiProvider).getGoogleDriveStatus();
      if (mounted) setState(() => _driveConnected = connected);
    } catch (_) {
      if (mounted) setState(() => _driveConnected = null);
    } finally {
      _checkingDrive = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull?.perfil ?? '';
    final canManage = canManageFeedback(profile);
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_refresh(), _checkDrive()]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 92),
            children: [
              AusterPageHeader(
                icon: Icons.help_outline_rounded,
                title: 'Ajuda',
                subtitle: 'Problemas, melhorias e novos recursos',
                trailing: IconButton.filled(
                  tooltip: 'Criar report',
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded),
                ),
              ),
              const SizedBox(height: 18),
              if (_driveConnected == false) ...[
                _driveNotice(),
                const SizedBox(height: 12),
              ],
              _filters(),
              const SizedBox(height: 14),
              FutureBuilder<PageResponse<FeedbackReport>>(
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
                  return _content(snapshot.data!, canManage);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Criar report',
        onPressed: _create,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _driveNotice() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AusterColors.infoBackground,
        border: Border.all(color: AusterColors.primary300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AusterColors.info),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Conecte o Google Drive antes de anexar evidências. Reports sem anexo continuam disponíveis.',
              ),
            ),
            IconButton(
              tooltip: 'Conectar Google Drive',
              onPressed: _connectDrive,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AusterColors.neutral200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _type == null,
                  onSelected: (_) => _setType(null),
                ),
                ChoiceChip(
                  label: const Text('Melhoria'),
                  selected: _type == 'MELHORIA',
                  onSelected: (_) => _setType('MELHORIA'),
                ),
                ChoiceChip(
                  label: const Text('Problema'),
                  selected: _type == 'BUG',
                  onSelected: (_) => _setType('BUG'),
                ),
                ChoiceChip(
                  label: const Text('Novo recurso'),
                  selected: _type == 'FEATURE_NOVA',
                  onSelected: (_) => _setType('FEATURE_NOVA'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Status', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<_FeedbackStatus>(
                segments: const [
                  ButtonSegment(
                    value: _FeedbackStatus.all,
                    label: Text('Todos'),
                  ),
                  ButtonSegment(
                    value: _FeedbackStatus.pending,
                    label: Text('Pendentes'),
                  ),
                  ButtonSegment(
                    value: _FeedbackStatus.discarded,
                    label: Text('Descartados'),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (selection) {
                  setState(() {
                    _status = selection.first;
                    _page = 0;
                    _future = _load();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setType(String? value) {
    setState(() {
      _type = value;
      _page = 0;
      _future = _load();
    });
  }

  Widget _content(PageResponse<FeedbackReport> page, bool canManage) {
    if (page.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Nenhum report encontrado.')),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < page.items.length; index++) ...[
          _feedbackTile(page.items[index], canManage),
          if (index < page.items.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                '${page.totalItems} reports · página ${page.page + 1} de ${page.totalPages == 0 ? 1 : page.totalPages}',
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

  Widget _feedbackTile(FeedbackReport report, bool canManage) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AusterColors.neutral200),
      ),
      child: ListTile(
        minTileHeight: 82,
        leading: CircleAvatar(
          backgroundColor: _feedbackColor(report).withValues(alpha: 0.12),
          foregroundColor: _feedbackColor(report),
          child: Icon(_feedbackIcon(report.type)),
        ),
        title: Text(report.title),
        subtitle: Text(
          [
            _typeLabel(report.type),
            if (canManage) report.userName,
            _feedbackStatusLabel(report),
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: canManage
            ? PopupMenuButton<_FeedbackAction>(
                tooltip: 'Ações do report',
                onSelected: (action) => _handleAction(action, report),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _FeedbackAction.copyMarkdown,
                    child: _FeedbackMenuAction(
                      icon: Icons.content_copy_rounded,
                      label: 'Copiar markdown',
                    ),
                  ),
                  if (report.active && report.issueNumber == null)
                    const PopupMenuItem(
                      value: _FeedbackAction.setIssue,
                      child: _FeedbackMenuAction(
                        icon: Icons.link_rounded,
                        label: 'Informar issue',
                      ),
                    ),
                  if (report.active)
                    const PopupMenuItem(
                      value: _FeedbackAction.discard,
                      child: _FeedbackMenuAction(
                        icon: Icons.block_rounded,
                        label: 'Descartar',
                      ),
                    ),
                ],
              )
            : const Icon(Icons.chevron_right_rounded),
        onTap: () => _showDetails(report),
      ),
    );
  }

  void _changePage(int delta) {
    setState(() {
      _page += delta;
      _future = _load();
    });
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FeedbackFormDialog(
        driveConnected: _driveConnected,
      ),
    );
    if (created != true || !mounted) return;
    _showMessage('Report enviado para análise.');
    setState(() {
      _page = 0;
      _future = _load();
    });
  }

  Future<void> _connectDrive() async {
    final launched = await ref.read(googleDriveAuthorizationProvider).launch();
    if (!mounted) return;
    if (!launched) {
      _showMessage('Não foi possível abrir a autorização do Google.');
    }
  }

  Future<void> _copyMarkdown(FeedbackReport report) async {
    try {
      final markdown =
          await ref.read(systemApiProvider).getFeedbackIssueMarkdown(report.id);
      await Clipboard.setData(ClipboardData(text: markdown));
      if (mounted) {
        _showMessage('Markdown copiado para criar a issue no GitHub.');
      }
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _setIssue(FeedbackReport report) async {
    final values = await showAusterRecordForm(
      context: context,
      title: 'Vincular issue',
      fields: const [
        RecordFieldSpec(
          key: 'numero',
          label: 'Número da issue',
          kind: RecordFieldKind.integer,
          required: true,
        ),
      ],
    );
    if (values == null) return;
    final number = values['numero'] as int;
    if (number <= 0) {
      _showMessage('Informe um número de issue válido.');
      return;
    }
    try {
      await ref.read(systemApiProvider).updateFeedbackIssue(report.id, number);
      if (!mounted) return;
      _showMessage('Issue #$number vinculada ao report.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  Future<void> _discard(FeedbackReport report) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Descartar report'),
            content: const Text(
              'Use esta ação apenas para spam ou duplicatas. O histórico será preservado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await ref.read(systemApiProvider).deactivateFeedback(report.id);
      if (!mounted) return;
      _showMessage('Report descartado.');
      await _refresh();
    } catch (error) {
      if (mounted) _showMessage(userFacingErrorMessage(error));
    }
  }

  void _handleAction(_FeedbackAction action, FeedbackReport report) {
    switch (action) {
      case _FeedbackAction.copyMarkdown:
        _copyMarkdown(report);
      case _FeedbackAction.setIssue:
        _setIssue(report);
      case _FeedbackAction.discard:
        _discard(report);
    }
  }

  Future<void> _showDetails(FeedbackReport report) {
    return showDialog<void>(
      context: context,
      builder: (context) => _FeedbackDetailsDialog(report: report),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FeedbackFormDialog extends ConsumerStatefulWidget {
  const _FeedbackFormDialog({required this.driveConnected});

  final bool? driveConnected;

  @override
  ConsumerState<_FeedbackFormDialog> createState() =>
      _FeedbackFormDialogState();
}

class _FeedbackFormDialogState extends ConsumerState<_FeedbackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'MELHORIA';
  _SelectedAttachment? _attachment;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('Novo report'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null) ...[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AusterColors.errorBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(_error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(
                      value: 'MELHORIA',
                      child: Text('Proposta de melhoria'),
                    ),
                    DropdownMenuItem(
                      value: 'BUG',
                      child: Text('Problema / Erro'),
                    ),
                    DropdownMenuItem(
                      value: 'FEATURE_NOVA',
                      child: Text('Novo recurso'),
                    ),
                  ],
                  onChanged: (value) => _type = value ?? _type,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  maxLength: 150,
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  minLines: 4,
                  maxLines: 7,
                  keyboardType: TextInputType.multiline,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 14),
                Text('Evidência',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (_attachment != null) ...[
                  if (_isImage(_attachment!.name))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        _attachment!.bytes,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attach_file_rounded),
                    title: Text(
                      _attachment!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_fileSize(_attachment!.bytes.length)),
                    trailing: IconButton(
                      tooltip: 'Remover anexo',
                      onPressed: _submitting
                          ? null
                          : () => setState(() => _attachment = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickAttachment,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: const Text('Anexar print'),
                  ),
                if (widget.driveConnected == false) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Google Drive desconectado. O envio sem anexo funciona normalmente.',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Conectar Google Drive',
                        onPressed: _connectDrive,
                        icon: const Icon(Icons.open_in_new_rounded),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_submitting ? 'Enviando...' : 'Enviar'),
        ),
      ],
    );
  }

  Future<void> _pickAttachment() async {
    try {
      final types = await ref.read(systemApiProvider).getAllowedFileTypes();
      final allowed = types['feedback'] ?? const [];
      final file = await FilePicker.pickFile(
        type: allowed.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: allowed.isEmpty ? null : allowed,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _attachment = _SelectedAttachment(name: file.name, bytes: bytes);
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = userFacingErrorMessage(error));
    }
  }

  Future<void> _connectDrive() async {
    final launched = await ref.read(googleDriveAuthorizationProvider).launch();
    if (!mounted || launched) return;
    setState(() => _error = 'Não foi possível abrir a autorização do Google.');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? attachmentKey;
      final attachment = _attachment;
      if (attachment != null) {
        final connected =
            await ref.read(systemApiProvider).getGoogleDriveStatus();
        if (!connected) {
          throw StateError(
            'Conecte o Google Drive antes de enviar uma evidência.',
          );
        }
        final uploaded = await ref.read(systemApiProvider).uploadFile(
              type: 'feedback',
              fileName: attachment.name,
              bytes: attachment.bytes,
            );
        attachmentKey = uploaded.key;
      }
      await ref.read(systemApiProvider).createFeedback(
            FeedbackInput(
              type: _type,
              title: _titleController.text,
              description: _descriptionController.text,
              attachmentKey: attachmentKey,
            ),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = userFacingErrorMessage(error);
          _submitting = false;
        });
      }
    }
  }
}

class _SelectedAttachment {
  const _SelectedAttachment({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class _FeedbackDetailsDialog extends ConsumerStatefulWidget {
  const _FeedbackDetailsDialog({required this.report});

  final FeedbackReport report;

  @override
  ConsumerState<_FeedbackDetailsDialog> createState() =>
      _FeedbackDetailsDialogState();
}

class _FeedbackDetailsDialogState
    extends ConsumerState<_FeedbackDetailsDialog> {
  Future<DownloadedFile>? _preview;

  @override
  void initState() {
    super.initState();
    final key = widget.report.attachmentKey;
    if (key != null && _isImage(key)) {
      _preview = ref.read(systemApiProvider).downloadFile(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: Text(report.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(_typeLabel(report.type))),
                  Chip(label: Text(_feedbackStatusLabel(report))),
                ],
              ),
              const SizedBox(height: 16),
              Text('Descrição', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              SelectableText(report.description),
              const SizedBox(height: 16),
              Text(
                'Reportado por ${report.userName} em ${_dateTime(report.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_preview != null) ...[
                const SizedBox(height: 16),
                FutureBuilder<DownloadedFile>(
                  future: _preview,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text(userFacingErrorMessage(snapshot.error!));
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        snapshot.data!.bytes,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
              ],
              if (report.attachmentKey != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _download,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Baixar anexo'),
                ),
              ],
              if (report.issueNumber != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openIssue,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text('Abrir issue #${report.issueNumber}'),
                ),
              ],
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
    );
  }

  Future<void> _download() async {
    try {
      final key = widget.report.attachmentKey!;
      final file = await ref.read(systemApiProvider).downloadFile(key);
      await FilePicker.saveFile(
        dialogTitle: 'Salvar evidência',
        fileName: file.fileName,
        bytes: file.bytes,
      );
      if (mounted) _message('Download concluído.');
    } catch (error) {
      if (mounted) _message(userFacingErrorMessage(error));
    }
  }

  Future<void> _openIssue() async {
    final uri = Uri.parse(
      'https://github.com/AusterTec/AusterAgX/issues/${widget.report.issueNumber}',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) _message('Não foi possível abrir a issue.');
  }

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

class _FeedbackMenuAction extends StatelessWidget {
  const _FeedbackMenuAction({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

enum _FeedbackStatus { all, pending, discarded }

enum _FeedbackAction { copyMarkdown, setIssue, discard }

String _typeLabel(String type) {
  return switch (type) {
    'MELHORIA' => 'Proposta de melhoria',
    'BUG' => 'Problema / Erro',
    'FEATURE_NOVA' => 'Novo recurso',
    _ => type,
  };
}

IconData _feedbackIcon(String type) {
  return switch (type) {
    'BUG' => Icons.bug_report_outlined,
    'FEATURE_NOVA' => Icons.auto_awesome_outlined,
    _ => Icons.lightbulb_outline_rounded,
  };
}

Color _feedbackColor(FeedbackReport report) {
  if (!report.active) return AusterColors.neutral500;
  if (report.issueNumber != null) return AusterColors.success;
  return AusterColors.warning;
}

String _feedbackStatusLabel(FeedbackReport report) {
  if (!report.active) return 'Descartado';
  if (report.issueNumber == null) return 'Pendente';
  return 'Issue #${report.issueNumber}';
}

bool _isImage(String name) {
  final lower = name.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg');
}

String _fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _dateTime(String iso) {
  final value = DateTime.tryParse(iso)?.toLocal();
  if (value == null) return iso;
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
