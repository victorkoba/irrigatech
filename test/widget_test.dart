import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:irrigatech/app.dart';
import 'package:irrigatech/services/auth_service.dart';
import 'package:irrigatech/services/irrigation_service.dart';

void main() {
  testWidgets('App smoke test - exibe LoginScreen quando deslogado', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => IrrigationService()),
        ],
        child: const IrrigaTechApp(),
      ),
    );

    // Verifica que o app inicia na tela de Login/Acesso
    expect(find.text('IrrigaTech'), findsWidgets);
    expect(find.text('ACESSO AO SISTEMA'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });

  testWidgets('App navigation test - exibe Dashboard ao carregar MainNavigationScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => IrrigationService()),
        ],
        child: const MaterialApp(
          home: MainNavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifica elementos fundamentais do Dashboard
    expect(find.text('IrrigaTech'), findsWidgets);
    expect(find.text('STATUS GERAL'), findsOneWidget);
    expect(find.text('PRÓXIMA IRRIGAÇÃO'), findsOneWidget);
  });
}
