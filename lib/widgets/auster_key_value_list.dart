import 'package:flutter/material.dart';

class AusterKeyValueList extends StatelessWidget {
  const AusterKeyValueList({required this.values, super.key});

  final Map<String, Object?> values;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.where((entry) {
      final value = entry.value;
      return value != null && value.toString().trim().isNotEmpty;
    }).toList(growable: false);
    if (entries.isEmpty) return const Text('Não informado.');

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 128,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(child: SelectableText(entry.value.toString())),
              ],
            ),
          ),
      ],
    );
  }
}
