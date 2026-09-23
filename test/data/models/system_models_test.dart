import 'package:auster_agx_mobile/data/models/system_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sensoriamento preserva dados necessarios para atualizacao', () {
    final sensing = RemoteSensing.fromJson({
      'id': 'sensoriamento-1',
      'codigoMapeamento': 'MAP-001',
      'fonte': 'DRONE',
      'pilotoId': 'piloto-1',
      'pilotoNome': 'Operador Auster',
      'qualidade': 'ALTA',
      'dataImagem': '2026-09-22',
      'estadioFenologico': 'V4',
      'observacoes': 'Voo concluido',
      'imagemMapeamentoPath': 'mapeamento/resultado.tif',
      'status': 'CONCLUIDO',
      'ativo': true,
      'createdAt': '2026-09-22T12:00:00Z',
    });

    final payload = RemoteSensingUpdateInput(
      source: sensing.source,
      pilotId: sensing.pilotId,
      quality: sensing.quality,
      imageDate: sensing.imageDate!,
      phenologicalStage: sensing.phenologicalStage,
      notes: sensing.notes,
      mappingImagePath: sensing.mappingImagePath,
    ).toJson();

    expect(sensing.mappingCode, 'MAP-001');
    expect(payload['pilotoId'], 'piloto-1');
    expect(payload['imagemMapeamentoPath'], 'mapeamento/resultado.tif');
    expect(payload, isNot(contains('satelite')));
  });

  test('auditoria converte mapas antigos e novos', () {
    final audit = AuditEntry.fromJson({
      'id': 42,
      'entidade': 'Demanda',
      'entidadeId': 'demanda-1',
      'usuarioId': 'usuario-1',
      'usuarioNome': 'Administrador',
      'acao': 'ATUALIZACAO',
      'valoresAntigos': {'status': 'PENDENTE'},
      'valoresNovos': {'status': 'CONCLUIDA'},
      'createdAt': '2026-09-22T12:00:00Z',
    });

    expect(audit.id, 42);
    expect(audit.oldValues?['status'], 'PENDENTE');
    expect(audit.newValues?['status'], 'CONCLUIDA');
  });

  test('feedback normaliza texto e omite anexo vazio', () {
    const input = FeedbackInput(
      type: 'MELHORIA',
      title: '  Nova funcionalidade  ',
      description: '  Detalhes da sugestao  ',
      attachmentKey: ' ',
    );

    final payload = input.toJson();
    expect(payload['titulo'], 'Nova funcionalidade');
    expect(payload['descricao'], 'Detalhes da sugestao');
    expect(payload, isNot(contains('anexoChave')));
  });

  test('arquivo enviado interpreta metadados da API', () {
    final file = UploadedFile.fromJson({
      'chave': 'feedback/evidencia.png',
      'tamanho': 2048,
      'contentType': 'image/png',
    });

    expect(file.key, 'feedback/evidencia.png');
    expect(file.size, 2048);
    expect(file.contentType, 'image/png');
  });
}
