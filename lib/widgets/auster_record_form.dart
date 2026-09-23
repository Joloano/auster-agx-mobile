import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum RecordFieldKind {
  text,
  email,
  phone,
  integer,
  decimal,
  multiline,
  date,
  boolean,
  choice,
}

class RecordFieldOption {
  const RecordFieldOption({required this.value, required this.label});

  final String value;
  final String label;
}

class RecordFieldSpec {
  const RecordFieldSpec({
    required this.key,
    required this.label,
    this.kind = RecordFieldKind.text,
    this.required = false,
    this.options = const [],
    this.helperText,
    this.prefixIcon,
    this.maxLength,
  });

  final String key;
  final String label;
  final RecordFieldKind kind;
  final bool required;
  final List<RecordFieldOption> options;
  final String? helperText;
  final IconData? prefixIcon;
  final int? maxLength;
}

Future<Map<String, dynamic>?> showAusterRecordForm({
  required BuildContext context,
  required String title,
  required List<RecordFieldSpec> fields,
  Map<String, dynamic> initialValues = const {},
  String submitLabel = 'Salvar',
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => _AusterRecordFormDialog(
      title: title,
      fields: fields,
      initialValues: initialValues,
      submitLabel: submitLabel,
    ),
  );
}

class _AusterRecordFormDialog extends StatefulWidget {
  const _AusterRecordFormDialog({
    required this.title,
    required this.fields,
    required this.initialValues,
    required this.submitLabel,
  });

  final String title;
  final List<RecordFieldSpec> fields;
  final Map<String, dynamic> initialValues;
  final String submitLabel;

  @override
  State<_AusterRecordFormDialog> createState() =>
      _AusterRecordFormDialogState();
}

class _AusterRecordFormDialogState extends State<_AusterRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final initial = widget.initialValues[field.key];
      if (field.kind == RecordFieldKind.boolean ||
          field.kind == RecordFieldKind.choice) {
        _values[field.key] = initial;
      } else {
        _controllers[field.key] = TextEditingController(
          text: initial?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in widget.fields) ...[
                  _buildField(field),
                  if (field != widget.fields.last) const SizedBox(height: 12),
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
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_rounded),
          label: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Widget _buildField(RecordFieldSpec field) {
    if (field.kind == RecordFieldKind.boolean) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(field.label),
        subtitle: field.helperText == null ? null : Text(field.helperText!),
        value: (_values[field.key] as bool?) ?? false,
        onChanged: (value) => setState(() => _values[field.key] = value),
      );
    }

    if (field.kind == RecordFieldKind.choice) {
      final current = _values[field.key]?.toString();
      final valid = field.options.any((option) => option.value == current);
      return DropdownButtonFormField<String>(
        initialValue: valid ? current : null,
        isExpanded: true,
        decoration: _decoration(field),
        items: field.options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.value,
                child: Text(
                  option.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: (value) => _values[field.key] = value,
        validator: (value) => field.required && (value == null || value.isEmpty)
            ? 'Campo obrigatório'
            : null,
      );
    }

    final controller = _controllers[field.key]!;
    return TextFormField(
      controller: controller,
      keyboardType: _keyboardType(field.kind),
      textInputAction: field.kind == RecordFieldKind.multiline
          ? TextInputAction.newline
          : TextInputAction.next,
      minLines: field.kind == RecordFieldKind.multiline ? 3 : 1,
      maxLines: field.kind == RecordFieldKind.multiline ? 6 : 1,
      maxLength: field.maxLength,
      readOnly: field.kind == RecordFieldKind.date,
      onTap: field.kind == RecordFieldKind.date
          ? () => _selectDate(field, controller)
          : null,
      decoration: _decoration(field).copyWith(
        suffixIcon: field.kind == RecordFieldKind.date
            ? const Icon(Icons.calendar_today_rounded)
            : null,
      ),
      validator: (value) => _validate(field, value),
    );
  }

  InputDecoration _decoration(RecordFieldSpec field) {
    return InputDecoration(
      labelText: field.label,
      helperText: field.helperText,
      prefixIcon: field.prefixIcon == null ? null : Icon(field.prefixIcon),
      alignLabelWithHint: field.kind == RecordFieldKind.multiline,
    );
  }

  TextInputType _keyboardType(RecordFieldKind kind) {
    return switch (kind) {
      RecordFieldKind.email => TextInputType.emailAddress,
      RecordFieldKind.phone => TextInputType.phone,
      RecordFieldKind.integer => TextInputType.number,
      RecordFieldKind.decimal => const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
      RecordFieldKind.multiline => TextInputType.multiline,
      _ => TextInputType.text,
    };
  }

  String? _validate(RecordFieldSpec field, String? value) {
    final text = value?.trim() ?? '';
    if (field.required && text.isEmpty) return 'Campo obrigatório';
    if (text.isEmpty) return null;
    if (field.kind == RecordFieldKind.email && !text.contains('@')) {
      return 'E-mail inválido';
    }
    if (field.kind == RecordFieldKind.integer && int.tryParse(text) == null) {
      return 'Informe um número inteiro';
    }
    if (field.kind == RecordFieldKind.decimal && _parseDecimal(text) == null) {
      return 'Informe um número válido';
    }
    return null;
  }

  Future<void> _selectDate(
    RecordFieldSpec field,
    TextEditingController controller,
  ) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(selected);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final result = <String, dynamic>{};
    for (final field in widget.fields) {
      if (field.kind == RecordFieldKind.boolean ||
          field.kind == RecordFieldKind.choice) {
        final value = _values[field.key];
        if (value != null) result[field.key] = value;
        continue;
      }

      final text = _controllers[field.key]!.text.trim();
      if (text.isEmpty) continue;
      result[field.key] = switch (field.kind) {
        RecordFieldKind.integer => int.parse(text),
        RecordFieldKind.decimal => _parseDecimal(text),
        _ => text,
      };
    }
    Navigator.pop(context, result);
  }
}

double? _parseDecimal(String value) {
  return double.tryParse(value.replaceAll(',', '.'));
}
