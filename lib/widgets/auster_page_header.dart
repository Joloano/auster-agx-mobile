import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AusterPageHeader extends StatelessWidget {
  const AusterPageHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: 8),
        ],
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AusterColors.primary500,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AusterColors.neutral700,
                    ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}
