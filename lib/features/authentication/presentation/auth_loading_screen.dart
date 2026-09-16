import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/auster_logo.dart';

class AuthLoadingScreen extends StatelessWidget {
  const AuthLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AusterLogo(width: 190),
              SizedBox(height: 28),
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(height: 14),
              Text(
                'Validando sessão...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AusterColors.neutral700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
