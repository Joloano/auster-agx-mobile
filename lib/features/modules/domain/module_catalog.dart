import 'package:flutter/material.dart';

import 'module_access.dart';

class MobileModuleDefinition {
  const MobileModuleDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.path,
    required this.icon,
    required this.section,
  });

  final AppModuleId id;
  final String title;
  final String subtitle;
  final String path;
  final IconData icon;
  final String section;
}

const mobileModuleCatalog = <MobileModuleDefinition>[
  MobileModuleDefinition(
    id: AppModuleId.usuarios,
    title: 'Usuários',
    subtitle: 'Contas, perfis e acessos',
    path: '/modulos/usuarios',
    icon: Icons.manage_accounts_rounded,
    section: 'Administração',
  ),
  MobileModuleDefinition(
    id: AppModuleId.perfil,
    title: 'Meu perfil',
    subtitle: 'Identidade e segurança da conta',
    path: '/modulos/perfil',
    icon: Icons.account_circle_rounded,
    section: 'Conta',
  ),
];

List<MobileModuleDefinition> modulesForProfile(String profile) {
  return mobileModuleCatalog
      .where((module) => canAccessModule(profile, module.id))
      .toList(growable: false);
}
