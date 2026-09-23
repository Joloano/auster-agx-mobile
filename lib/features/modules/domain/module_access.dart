enum AppModuleId {
  dashboard,
  demandas,
  clientes,
  pedidos,
  fazendas,
  culturas,
  estadiosFenologicos,
  usuarios,
  mapeamento,
  auditoria,
  ajuda,
  perfil,
}

const allAuthenticatedProfiles = <String>{
  'SUPER_ADMIN',
  'USUARIO_TECNICO_PRESCRICAO',
  'USUARIO_CONSULTOR_CTV',
  'USUARIO_ASSISTENTE_ATV',
  'USUARIO_GESTOR_ADMINISTRATIVO',
};

const administrativeReadProfiles = <String>{
  'SUPER_ADMIN',
  'USUARIO_TECNICO_PRESCRICAO',
  'USUARIO_GESTOR_ADMINISTRATIVO',
};

const demandaCreationProfiles = <String>{
  'SUPER_ADMIN',
  'USUARIO_TECNICO_PRESCRICAO',
  'USUARIO_CONSULTOR_CTV',
};

const moduleProfiles = <AppModuleId, Set<String>>{
  AppModuleId.dashboard: allAuthenticatedProfiles,
  AppModuleId.demandas: administrativeReadProfiles,
  AppModuleId.clientes: allAuthenticatedProfiles,
  AppModuleId.pedidos: administrativeReadProfiles,
  AppModuleId.fazendas: administrativeReadProfiles,
  AppModuleId.culturas: allAuthenticatedProfiles,
  AppModuleId.estadiosFenologicos: administrativeReadProfiles,
  AppModuleId.usuarios: {'SUPER_ADMIN'},
  AppModuleId.mapeamento: allAuthenticatedProfiles,
  AppModuleId.auditoria: {'SUPER_ADMIN'},
  AppModuleId.ajuda: allAuthenticatedProfiles,
  AppModuleId.perfil: allAuthenticatedProfiles,
};

bool canAccessModule(String profile, AppModuleId module) {
  return moduleProfiles[module]?.contains(profile) ?? false;
}

bool canCreateDemanda(String profile) {
  return demandaCreationProfiles.contains(profile);
}
