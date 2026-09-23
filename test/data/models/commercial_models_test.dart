import 'package:auster_agx_mobile/data/models/commercial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pedido separa payload de criação e atualização', () {
    const input = OrderInput(
      clientId: 'cliente-1',
      nickname: 'Safra 2026',
      notes: 'Prioridade alta',
    );

    expect(input.toCreateJson()['clienteId'], 'cliente-1');
    expect(input.toUpdateJson().containsKey('clienteId'), isFalse);
  });

  test('demanda omite sensoriamento quando não informado', () {
    const input = DemandCreateInput(
      orderId: 'pedido-1',
      type: 'SMART_SEEDING',
      representativeId: 'usuario-1',
    );

    final payload = input.toJson();
    expect(payload['pedidoId'], 'pedido-1');
    expect(payload['tipo'], 'SMART_SEEDING');
    expect(payload.containsKey('fonte'), isFalse);
    expect(payload.containsKey('satelite'), isFalse);
  });
}
