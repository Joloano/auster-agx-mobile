const cultureGroupValues = <String>[
  'SOJA',
  'MILHO',
  'MILHO_SEMENTE',
  'ALGODAO',
  'FEIJAO',
  'CEREAIS_DE_INVERNO',
  'CAPIM',
  'CITROS',
  'CRUCIFERA',
  'CRUCIFERA_DE_COBERTURA',
  'GRAMINEA_DE_COBERTURA',
  'GRAMINEA_BAIXA_PLASTICIDADE',
  'LEGUMINOSA_DE_COBERTURA',
  'OUTRAS_LEGUMINOSAS',
  'OLEAGINOSAS',
  'HORTUFRUTI',
  'BATATA',
  'RAIZES_COMESTIVEIS',
  'ADUBACAO_VERDE',
];

const cultureGroupLabels = <String, String>{
  'SOJA': 'Soja',
  'MILHO': 'Milho',
  'MILHO_SEMENTE': 'Milho semente',
  'ALGODAO': 'Algodão',
  'FEIJAO': 'Feijão',
  'CEREAIS_DE_INVERNO': 'Cereais de inverno',
  'CAPIM': 'Capim',
  'CITROS': 'Citros',
  'CRUCIFERA': 'Crucífera',
  'CRUCIFERA_DE_COBERTURA': 'Crucífera de cobertura',
  'GRAMINEA_DE_COBERTURA': 'Gramínea de cobertura',
  'GRAMINEA_BAIXA_PLASTICIDADE': 'Gramínea de baixa plasticidade',
  'LEGUMINOSA_DE_COBERTURA': 'Leguminosa de cobertura',
  'OUTRAS_LEGUMINOSAS': 'Outras leguminosas',
  'OLEAGINOSAS': 'Oleaginosas',
  'HORTUFRUTI': 'Hortifruti',
  'BATATA': 'Batata',
  'RAIZES_COMESTIVEIS': 'Raízes comestíveis',
  'ADUBACAO_VERDE': 'Adubação verde',
};

const precocityValues = <String>[
  'HIPERPRECOCE',
  'SUPERPRECOCE',
  'PRECOCE',
  'MEDIOPRECOCE',
  'MEDIO',
  'MEDIO_TARDIO',
  'TARDIO',
];

const precocityLabels = <String, String>{
  'HIPERPRECOCE': 'Hiperprecoce',
  'SUPERPRECOCE': 'Superprecoce',
  'PRECOCE': 'Precoce',
  'MEDIOPRECOCE': 'Médio-precoce',
  'MEDIO': 'Médio',
  'MEDIO_TARDIO': 'Médio-tardio',
  'TARDIO': 'Tardio',
};

const demandTypeValues = <String>[
  'SMART_N',
  'SMART_BRAKE',
  'SMART_SEEDING',
];

const demandTypeLabels = <String, String>{
  'SMART_N': 'Smart-N',
  'SMART_BRAKE': 'Smart-Brake',
  'SMART_SEEDING': 'Smart-Seeding',
};

const fertilizationTypeLabels = <String, String>{
  'SEMEADURA': 'Semeadura',
  'INCORPORADA': 'Incorporada',
  'COBERTURA': 'Cobertura',
};

String labelFor(Map<String, String> labels, String? value) {
  if (value == null || value.isEmpty) return '-';
  return labels[value] ?? value.replaceAll('_', ' ');
}
