import 'package:flutter_test/flutter_test.dart';
import 'package:irrigatech/models/alert_model.dart';
import 'package:irrigatech/models/sector_model.dart';
import 'package:irrigatech/screens/auth/auth_widgets.dart';

void main() {
  group('Validações de Entrada (auth_widgets)', () {
    test('validateName valida preenchimento e tamanho', () {
      expect(validateName(null), 'Informe seu nome');
      expect(validateName(''), 'Informe seu nome');
      expect(validateName('   '), 'Informe seu nome');
      expect(validateName('A'), 'Nome muito curto');
      expect(validateName('Victor Koba'), isNull);
    });

    test('validateEmail valida formato e preenchimento', () {
      expect(validateEmail(null), 'Informe seu e-mail');
      expect(validateEmail(''), 'Informe seu e-mail');
      expect(validateEmail('invalido'), 'E-mail inválido');
      expect(validateEmail('usuario@dominio'), 'E-mail inválido');
      expect(validateEmail('usuario@dominio.com'), isNull);
      expect(validateEmail('operador@irrigatech.com'), isNull);
    });

    test('validatePassword valida preenchimento e mínimo de 6 caracteres', () {
      expect(validatePassword(null), 'Informe sua senha');
      expect(validatePassword(''), 'Informe sua senha');
      expect(validatePassword('12345'), 'Mínimo de 6 caracteres');
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('senhaSegura!'), isNull);
    });

    test('validateConfirm valida confirmação de senha', () {
      expect(validateConfirm(null, 'senha123'), 'Repita a senha');
      expect(validateConfirm('', 'senha123'), 'Repita a senha');
      expect(validateConfirm('senhaDiferente', 'senha123'), 'As senhas não conferem');
      expect(validateConfirm('senha123', 'senha123'), isNull);
    });
  });

  group('Modelos de Dados (SectorModel & AlertModel)', () {
    test('SectorModel - Instanciação e copyWith', () {
      const sector = SectorModel(
        id: 'setor_test',
        name: 'Setor Teste',
        region: 'Norte',
        status: SectorStatus.idle,
        flowRate: 0.0,
        moisture: 42.0,
        temperature: 26.0,
      );

      expect(sector.id, 'setor_test');
      expect(sector.status, SectorStatus.idle);
      expect(sector.flowRate, 0.0);

      final updated = sector.copyWith(
        status: SectorStatus.irrigating,
        flowRate: 35.5,
      );

      expect(updated.id, 'setor_test');
      expect(updated.status, SectorStatus.irrigating);
      expect(updated.flowRate, 35.5);
      expect(updated.moisture, 42.0); // preservado
    });

    test('AlertModel - Instanciação e severidade', () {
      final now = DateTime.now();
      final alert = AlertModel(
        id: 'alert_test',
        title: 'Alerta Teste',
        description: 'Descrição de teste',
        severity: AlertSeverity.critical,
        timestamp: now,
      );

      expect(alert.id, 'alert_test');
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.timestamp, now);
    });
  });
}
