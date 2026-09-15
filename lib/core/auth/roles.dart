const perfilLabels = {
  'SUPER_ADMIN': 'Super administrador',
  'USUARIO_TECNICO_PRESCRICAO': 'Tecnico de prescricao',
  'USUARIO_CONSULTOR_CTV': 'Consultor CTV',
  'USUARIO_ASSISTENTE_ATV': 'Assistente ATV',
  'USUARIO_GESTOR_ADMINISTRATIVO': 'Gestor administrativo',
};

String perfilLabel(String perfil) => perfilLabels[perfil] ?? perfil;

bool isAdministrativeProfile(String perfil) {
  return perfil == 'SUPER_ADMIN' || perfil == 'USUARIO_TECNICO_PRESCRICAO';
}
