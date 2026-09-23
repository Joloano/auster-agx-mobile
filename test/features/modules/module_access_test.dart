import 'package:auster_agx_mobile/features/modules/domain/module_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('super administrador acessa modulos administrativos', () {
    expect(
      canAccessModule('SUPER_ADMIN', AppModuleId.usuarios),
      isTrue,
    );
    expect(
      canAccessModule('SUPER_ADMIN', AppModuleId.auditoria),
      isTrue,
    );
  });

  test('consultor acessa clientes mas nao auditoria', () {
    expect(
      canAccessModule('USUARIO_CONSULTOR_CTV', AppModuleId.clientes),
      isTrue,
    );
    expect(
      canAccessModule('USUARIO_CONSULTOR_CTV', AppModuleId.auditoria),
      isFalse,
    );
  });

  test('somente perfis autorizados criam demandas', () {
    expect(canCreateDemanda('USUARIO_CONSULTOR_CTV'), isTrue);
    expect(canCreateDemanda('USUARIO_ASSISTENTE_ATV'), isFalse);
  });

  test('pedidos seguem a leitura administrativa do sistema web', () {
    expect(
      canAccessModule('USUARIO_GESTOR_ADMINISTRATIVO', AppModuleId.pedidos),
      isTrue,
    );
    expect(
      canAccessModule('USUARIO_CONSULTOR_CTV', AppModuleId.pedidos),
      isFalse,
    );
    expect(canCreateOrder('USUARIO_CONSULTOR_CTV'), isTrue);
    expect(canUpdateOrder('USUARIO_CONSULTOR_CTV'), isFalse);
  });

  test('catálogos agronômicos respeitam leitura e escrita por perfil', () {
    expect(
      canAccessModule('USUARIO_CONSULTOR_CTV', AppModuleId.culturas),
      isTrue,
    );
    expect(
      canAccessModule(
        'USUARIO_GESTOR_ADMINISTRATIVO',
        AppModuleId.estadiosFenologicos,
      ),
      isTrue,
    );
    expect(canManageAgronomicData('USUARIO_TECNICO_PRESCRICAO'), isTrue);
    expect(canManageAgronomicData('USUARIO_GESTOR_ADMINISTRATIVO'), isFalse);
  });

  test('operações de mapeamento respeitam os papéis da API', () {
    expect(canManageMappingData('SUPER_ADMIN'), isTrue);
    expect(canManageMappingData('USUARIO_TECNICO_PRESCRICAO'), isTrue);
    expect(canManageMappingData('USUARIO_ASSISTENTE_ATV'), isFalse);
    expect(canOperateMapping('USUARIO_ASSISTENTE_ATV'), isTrue);
    expect(canOperateMapping('USUARIO_CONSULTOR_CTV'), isFalse);
  });

  test('somente perfis administrativos gerenciam reports', () {
    expect(canManageFeedback('SUPER_ADMIN'), isTrue);
    expect(canManageFeedback('USUARIO_TECNICO_PRESCRICAO'), isTrue);
    expect(canManageFeedback('USUARIO_GESTOR_ADMINISTRATIVO'), isFalse);
  });
}
