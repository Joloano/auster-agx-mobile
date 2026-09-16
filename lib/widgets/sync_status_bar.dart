import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/providers/core_providers.dart';
import '../data/sync/sync_providers.dart';

class SyncStatusBar extends ConsumerWidget {
  const SyncStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineStatusProvider).valueOrNull ?? true;
    final pending = ref.watch(pendingSyncCountProvider).valueOrNull ?? 0;
    ref.watch(syncServiceProvider);

    final info = _statusInfo(context, online: online, pending: pending);
    if (info == null) return const SizedBox.shrink();

    return Material(
      color: info.color.withValues(alpha: 0.12),
      child: InkWell(
        onTap: online
            ? () async {
                final sync = await ref.read(syncServiceProvider.future);
                await sync.processPending();
                ref.invalidate(pendingSyncCountProvider);
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
  }) {
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
