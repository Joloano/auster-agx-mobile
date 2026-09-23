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
    id: AppModuleId.clientes,
    title: 'Clientes',
    subtitle: 'Carteiras, contatos e vínculos',
    path: '/modulos/clientes',
    icon: Icons.people_alt_rounded,
    section: 'Operação',
  ),
  MobileModuleDefinition(
    id: AppModuleId.pedidos,
    title: 'Pedidos',
    subtitle: 'Contratos e demandas relacionadas',
    path: '/modulos/pedidos',
    icon: Icons.receipt_long_rounded,
    section: 'Operação',
  ),
  MobileModuleDefinition(
    id: AppModuleId.fazendas,
    title: 'Fazendas',
    subtitle: 'Propriedades, talhões e equipes',
    path: '/modulos/fazendas',
    icon: Icons.agriculture_rounded,
    section: 'Campo',
  ),
  MobileModuleDefinition(
    id: AppModuleId.culturas,
    title: 'Culturas',
    subtitle: 'Cultivares e serviços atendidos',
    path: '/modulos/culturas',
    icon: Icons.nature_rounded,
    section: 'Agronomia',
  ),
  MobileModuleDefinition(
    id: AppModuleId.estadiosFenologicos,
    title: 'Estádios fenológicos',
    subtitle: 'Catálogo agronômico por cultura',
    path: '/modulos/estadios-fenologicos',
    icon: Icons.timeline_rounded,
    section: 'Agronomia',
  ),
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
