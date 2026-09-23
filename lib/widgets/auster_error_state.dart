import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AusterErrorState extends StatelessWidget {
  const AusterErrorState({
    required this.message,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final String message;
  final Future<void> Function()? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 16,
        vertical: compact ? 12 : 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: AusterColors.neutral700,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}
