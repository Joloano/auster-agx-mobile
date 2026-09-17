import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/providers/core_providers.dart';
import '../data/sync/sync_providers.dart';
import '../data/sync/sync_service.dart';

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineStatusProvider).valueOrNull ?? true;
    final summary = ref.watch(syncQueueSummaryProvider).valueOrNull ??
        const SyncQueueSummary(pending: 0, failed: 0);
    ref.watch(syncServiceProvider);

    final info = _statusInfo(
      context,
      online: online,
      pending: summary.pending,
      failed: summary.failed,
    );
    if (info == null) return const SizedBox.shrink();

    return Material(
      color: info.color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: online && summary.pending > 0
            ? () async {
                final sync = await ref.read(syncServiceProvider.future);
                await sync.processPending();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(info.icon, size: 16, color: info.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.text,
                  style: TextStyle(color: info.color, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({IconData icon, String text, Color color})? _statusInfo(
    BuildContext context, {
    required bool online,
    required int pending,
    required int failed,
  }) {
    if (failed > 0) {
      final failedText =
          '$failed ${failed == 1 ? "alteração precisa" : "alterações precisam"} de revisão';
      final pendingText =
          '$pending ${pending == 1 ? "alteração pendente" : "alterações pendentes"}';
      return (
        icon: Icons.sync_problem_rounded,
        text: pending > 0 ? '$failedText · $pendingText' : failedText,
        color: AusterColors.error,
      );
    }
    if (!online) {
      return (
        icon: Icons.cloud_off_rounded,
        text: pending > 0
            ? 'Offline · $pending ${pending == 1 ? "alteração" : "alterações"} aguardando envio'
            : 'Offline · exibindo dados salvos',
        color: AusterColors.neutral700,
      );
    }
    if (pending > 0) {
      return (
        icon: Icons.cloud_upload_rounded,
        text:
            '$pending ${pending == 1 ? "alteração pendente" : "alterações pendentes"} · toque para enviar',
        color: AusterColors.primary700,
      );
    }
    return null;
  }
}
