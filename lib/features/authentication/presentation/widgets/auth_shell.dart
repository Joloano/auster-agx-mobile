import 'package:flutter/material.dart';

import '../../../../core/app_theme.dart';
import '../../../../widgets/auster_logo.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 8,
                shadowColor: AusterColors.primary900.withValues(alpha: 0.16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AusterColors.neutral900.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: AusterLogo(width: 220)),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AusterColors.neutral700,
                                ),
                          ),
                          const SizedBox(height: 24),
                          child,
                        ],
                      ),
                      if (action != null)
                        Positioned(
                          top: -10,
                          right: -10,
                          child: action!,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration authFieldDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(999),
    borderSide: const BorderSide(color: AusterColors.neutral300),
  );
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(
        color: AusterColors.primary500,
        width: 2,
      ),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: AusterColors.error),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: AusterColors.error, width: 2),
    ),
  );
}

ButtonStyle authPrimaryButtonStyle() {
  return FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    shape: const StadiumBorder(),
    backgroundColor: AusterColors.primary500,
    foregroundColor: Colors.white,
  );
}

class AuthErrorMessage extends StatelessWidget {
  const AuthErrorMessage(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AusterColors.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0xFFE8A39E)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AusterColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8F231D),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
