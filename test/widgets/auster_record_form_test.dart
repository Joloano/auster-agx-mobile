import 'package:auster_agx_mobile/widgets/auster_record_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valida campos e devolve valores tipados', (tester) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await showAusterRecordForm(
                  context: context,
                  title: 'Cadastro',
                  fields: const [
                    RecordFieldSpec(
                      key: 'nome',
                      label: 'Nome',
                      required: true,
                    ),
                    RecordFieldSpec(
                      key: 'area',
                      label: 'Área',
                      kind: RecordFieldKind.decimal,
                    ),
                  ],
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Fazenda A');
    await tester.enterText(find.byType(TextFormField).last, '10,5');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(result?['nome'], 'Fazenda A');
    expect(result?['area'], 10.5);
  });
}
