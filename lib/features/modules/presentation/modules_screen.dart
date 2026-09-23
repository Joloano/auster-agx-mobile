import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_theme.dart';
import '../../../widgets/auster_page_header.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../domain/module_catalog.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final modules = user == null
        ? const <MobileModuleDefinition>[]
        : modulesForProfile(user.perfil);
    final sections = <String, List<MobileModuleDefinition>>{};
    for (final module in modules) {
      sections.putIfAbsent(module.section, () => []).add(module);
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          const AusterPageHeader(
            icon: Icons.apps_rounded,
            title: 'Módulos',
            subtitle: 'Operações disponíveis para o seu perfil',
          ),
          const SizedBox(height: 22),
          for (final section in sections.entries) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                section.key,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...section.value.map(
              (module) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AusterColors.neutral200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    minTileHeight: 72,
                    leading: Icon(
                      module.icon,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(module.title),
                    subtitle: Text(module.subtitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go(module.path),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
