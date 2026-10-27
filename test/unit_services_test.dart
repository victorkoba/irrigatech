import 'package:flutter_test/flutter_test.dart';
import 'package:irrigatech/models/sector_model.dart';
import 'package:irrigatech/services/irrigation_service.dart';

void main() {
  group('IrrigationService - Regras de Negócio e Estado', () {
    late IrrigationService service;

    setUp(() {
      service = IrrigationService();
    });

    test('Estado inicial padrão', () {
      expect(service.isSystemActive, isTrue);
      expect(service.operationMode, 'Automático');
      expect(service.currentTabIndex, 0);
      expect(service.sectors.length, 5);
      expect(service.alerts.length, 2);
    });

    test('Navegação entre abas', () {
      service.setTabIndex(2);
      expect(service.currentTabIndex, 2);
      service.setTabIndex(0);
      expect(service.currentTabIndex, 0);
    });

    test('Seleção de setor', () {
      service.setSelectedSector('setor_b');
      expect(service.selectedSectorId, 'setor_b');
      expect(service.selectedSector.name, 'Setor B');
    });

    test('Acionamento de setor ocioso (idle -> irrigating)', () {
      final initialSectorB = service.sectors.firstWhere((s) => s.id == 'setor_b');
      expect(initialSectorB.status, SectorStatus.idle);
      expect(initialSectorB.flowRate, 0.0);

      service.toggleSectorIrrigation('setor_b');

      final toggledSectorB = service.sectors.firstWhere((s) => s.id == 'setor_b');
      expect(toggledSectorB.status, SectorStatus.irrigating);
      expect(toggledSectorB.flowRate, 40.0);
    });

    test('Bloqueio de acionamento em setor com erro (Setor C com vazamento)', () {
      final sectorC = service.sectors.firstWhere((s) => s.id == 'setor_c');
      expect(sectorC.status, SectorStatus.error);

      service.toggleSectorIrrigation('setor_c');

      final afterToggle = service.sectors.firstWhere((s) => s.id == 'setor_c');
      expect(afterToggle.status, SectorStatus.error);
      expect(afterToggle.flowRate, 0.0);
    });

    test('Ajuste de vazão de setor ativo', () {
      service.toggleSectorIrrigation('setor_b'); // Liga Setor B
      service.setSectorFlowRate('setor_b', 65.0);

      final sectorB = service.sectors.firstWhere((s) => s.id == 'setor_b');
      expect(sectorB.flowRate, 65.0);
    });

    test('Protocolo de Parada de Emergência (Emergency Stop)', () {
      expect(service.isSystemActive, isTrue);

      service.emergencyStop();

      expect(service.isSystemActive, isFalse);
      for (final s in service.sectors) {
        expect(s.flowRate, 0.0);
        expect(s.status != SectorStatus.irrigating, isTrue);
      }
    });

    test('Reativação do Sistema (Resume)', () {
      service.emergencyStop();
      expect(service.isSystemActive, isFalse);

      service.resumeSystem();
      expect(service.isSystemActive, isTrue);
    });

    test('Alternância de Modo de Operação', () {
      service.setOperationMode('Manual');
      expect(service.operationMode, 'Manual');

      service.setOperationMode('Automático');
      expect(service.operationMode, 'Automático');
    });

    test('Ajuste de Parâmetros de Umidade', () {
      service.updateParameters(25.0, 80.0);
      expect(service.minMoistureTrigger, 25.0);
      expect(service.maxMoistureCutoff, 80.0);
    });

    test('Descarte de Alerta', () {
      expect(service.alerts.length, 2);
      service.dismissAlert('alert_1');
      expect(service.alerts.length, 1);
      expect(service.alerts.any((a) => a.id == 'alert_1'), isFalse);
    });
  });
}
