import 'package:auster_agx_mobile/widgets/auster_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe mensagem e aciona nova tentativa', (tester) async {
    var attempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AusterErrorState(
            message: 'Falha temporaria.',
            onRetry: () async {
              attempts++;
            },
          ),
        ),
      ),
    );

    expect(find.text('Falha temporaria.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();

    expect(attempts, 1);
  });
}
