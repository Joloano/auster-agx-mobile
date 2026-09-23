import 'package:auster_agx_mobile/data/models/page_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte a pagina oficial da API', () {
    final page = PageResponse<JsonMap>.fromJson(
      {
        'conteudo': [
          {'id': '1', 'nome': 'Cliente A'},
        ],
        'totalElementos': 21,
        'totalPaginas': 2,
        'pagina': 0,
        'tamanho': 20,
      },
      (json) => json,
    );

    expect(page.items.single['nome'], 'Cliente A');
    expect(page.totalItems, 21);
    expect(page.hasNextPage, isTrue);
    expect(page.hasPreviousPage, isFalse);
  });
}
