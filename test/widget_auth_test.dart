import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:irrigatech/screens/auth/login_screen.dart';
import 'package:irrigatech/screens/profile/profile_screen.dart';
import 'package:irrigatech/services/auth_service.dart';
import 'package:irrigatech/services/irrigation_service.dart';

void main() {
  Widget createAuthWidget(Widget child, {AuthService? authService}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => authService ?? AuthService(),
        ),
        ChangeNotifierProvider<IrrigationService>(
          create: (_) => IrrigationService(),
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Testes de Widget - Tela de Login (Sem Auto-Cadastro Público)', () {
    testWidgets('Renderiza elementos fundamentais de login e oculta Cadastre-se', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAuthWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('IrrigaTech'), findsWidgets);
      expect(find.text('ACESSO AO SISTEMA'), findsOneWidget);
      expect(find.text('E-mail'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('ENTRAR'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsNothing);
      expect(
        find.text('Novos usuários são cadastrados exclusivamente pelo usuário ADMIN.'),
        findsOneWidget,
      );
    });

    testWidgets('Validação de formulário vazio ao clicar em Entrar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAuthWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // Clica em Entrar sem preencher campos
      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();

      expect(find.text('Informe seu e-mail'), findsOneWidget);
      expect(find.text('Informe sua senha'), findsOneWidget);
    });

    testWidgets('Validação de e-mail com formato inválido', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createAuthWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'email-invalido');
      await tester.tap(find.text('ENTRAR'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail inválido'), findsOneWidget);
    });
  });

  group('Testes de Widget - Tela de Perfil e Permissões (ADMIN vs Operador)', () {
    testWidgets('Usuário victor@gmail.com exibe função ADMIN e formulário para adicionar usuários', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = AuthService();
      auth.setTestUser({
        'id': 3,
        'name': 'Victor Koba',
        'email': 'victor@gmail.com',
        'role': 'ADMIN',
      });

      await tester.pumpWidget(createAuthWidget(const ProfileScreen(), authService: auth));
      await tester.pump();

      expect(find.text('Perfil'), findsOneWidget);
      expect(find.text('Victor Koba'), findsWidgets);
      expect(find.text('victor@gmail.com'), findsOneWidget);
      expect(find.text('ADMIN'), findsWidgets);
      expect(find.text('Adicionar Novo Usuário'), findsOneWidget);
      expect(find.text('ADICIONAR USUÁRIO'), findsOneWidget);
    });

    testWidgets('Usuário Operador exibe função Operador e oculta formulário de cadastro', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = AuthService();
      auth.setTestUser({
        'id': 1,
        'name': 'Operador Padrão',
        'email': 'operador@irrigatech.com',
        'role': 'Operador',
      });

      await tester.pumpWidget(createAuthWidget(const ProfileScreen(), authService: auth));
      await tester.pump();

      expect(find.text('Operador Padrão'), findsWidgets);
      expect(find.text('operador@irrigatech.com'), findsOneWidget);
      expect(find.text('Operador'), findsWidgets);
      expect(find.text('Adicionar Novo Usuário'), findsNothing);
    });
  });
}
