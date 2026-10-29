import 'package:flutter_test/flutter_test.dart';
import 'package:irrigatech/models/sector_model.dart';
import 'package:irrigatech/services/irrigation_service.dart';

void main() {
  group('IrrigationService - Regras de Negócio e Estado', () {
    late IrrigationService service;

    setUp(() {
      service = IrrigationService();
    });

    test('Estado inicial padrão (sem alertas falsos quando valores estão normais)', () {
      expect(service.isSystemActive, isTrue);
      expect(service.operationMode, 'Automático');
      expect(service.currentTabIndex, 0);
      expect(service.sectors.length, 5);
      expect(service.alerts.length, 0);
      expect(service.statusCardDescription, isNotEmpty);
      expect(service.hourlyMinutesRemaining, greaterThan(0));
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

    test('Protocolo de Parada de Emergência (Emergency Stop) salva snapshot dos setores ativos', () {
      expect(service.isSystemActive, isTrue);
      // Ativa também Setor B com vazão 40.0
      service.toggleSectorIrrigation('setor_b');
      expect(service.sectors.firstWhere((s) => s.id == 'setor_a').status, SectorStatus.irrigating);
      expect(service.sectors.firstWhere((s) => s.id == 'setor_b').status, SectorStatus.irrigating);

      service.emergencyStop();

      expect(service.isSystemActive, isFalse);
      expect(service.savedActiveSectors.length, 2);
      expect(service.savedActiveSectors.any((s) => s.id == 'setor_a'), isTrue);
      expect(service.savedActiveSectors.any((s) => s.id == 'setor_b'), isTrue);

      for (final s in service.sectors) {
        expect(s.flowRate, 0.0);
        expect(s.status != SectorStatus.irrigating, isTrue);
      }
    });

    test('Reativação do Sistema (Resume) restaura os setores que estavam ativos antes de desligar tudo', () {
      // 1. Ativa Setor B além do Setor A com vazão específica
      service.toggleSectorIrrigation('setor_b');
      service.setSectorFlowRate('setor_b', 55.0);

      // 2. Parada de emergência
      service.emergencyStop();
      expect(service.isSystemActive, isFalse);
      for (final s in service.sectors) {
        expect(s.status != SectorStatus.irrigating, isTrue);
      }

      // 3. Reativação restaura Setor A e Setor B com suas vazões
      service.resumeSystem();
      expect(service.isSystemActive, isTrue);

      final sectorA = service.sectors.firstWhere((s) => s.id == 'setor_a');
      final sectorB = service.sectors.firstWhere((s) => s.id == 'setor_b');
      expect(sectorA.status, SectorStatus.irrigating);
      expect(sectorA.flowRate, 45.0);
      expect(sectorB.status, SectorStatus.irrigating);
      expect(sectorB.flowRate, 55.0);
    });

    test('Reativação automática do Sistema ao ativar setor individual', () {
      service.emergencyStop();
      expect(service.isSystemActive, isFalse);

      service.toggleSectorIrrigation('setor_b');
      expect(service.isSystemActive, isTrue);
      final sectorB = service.sectors.firstWhere((s) => s.id == 'setor_b');
      expect(sectorB.status, SectorStatus.irrigating);
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

    test('Geração condicional de Alerta por Água, Energia e Temperatura muito altos e Descarte', () {
      expect(service.alerts.length, 0);

      // Simula setor com água, energia e temperatura muito altos
      service.updateSectorTelemetry(
        'setor_a',
        flowRate: 95.0,
        energyConsumption: 130.0,
        temperature: 39.0,
      );

      expect(service.alerts.length, 1);
      expect(service.alerts.first.id, 'alert_threshold_setor_a');
      expect(service.alerts.first.title, contains('Setor A'));

      // Descarta o alerta
      service.dismissAlert('alert_threshold_setor_a');
      expect(service.alerts.length, 0);
    });

    test('Agendamento da Próxima Irrigação', () {
      service.updateSchedule('16:15', 'Setor A e B (Milho)', dailyProgressPct: 75.0);
      expect(service.nextIrrigationTime, '16:15');
      expect(service.nextIrrigationSectors, 'Setor A e B (Milho)');
      expect(service.dailyProgressPct, 75.0);
    });

    test('Adição de novo setor no controle reflete na lista e no monitoramento', () async {
      final initialCount = service.sectors.length;
      final newSector = await service.addSector(
        name: 'Setor F',
        region: 'Noroeste',
        moisture: 52.0,
        temperature: 24.0,
      );

      expect(service.sectors.length, initialCount + 1);
      expect(newSector.name, 'Setor F');
      expect(newSector.region, 'Noroeste');
      expect(service.sectors.any((s) => s.id == newSector.id), isTrue);

      service.setSelectedSector(newSector.id);
      expect(service.selectedSector.name, 'Setor F');
      expect(service.selectedSector.moisture, 52.0);

      // Exclusão do setor no Controle remove também do Monitoramento
      await service.removeSector(newSector.id);
      expect(service.sectors.any((s) => s.id == newSector.id), isFalse);
      expect(service.sectors.length, initialCount);
      expect(service.selectedSector.id, isNot(equals(newSector.id)));
    });

    test('Edição de setor, chave Liga/Desliga (isEnabled) e ativação automática por umidade abaixo da ideal', () async {
      // Setor B começa em 60% de umidade (idle)
      // Editamos a umidade ideal do Setor B para 70%: como 60% < 70%, a irrigação ativa automaticamente!
      await service.editSector(
        id: 'setor_b',
        name: 'Setor B Editado',
        region: 'Leste-Sul',
        idealMoisture: 70.0,
        minMoistureTrigger: 40.0,
        maxMoistureCutoff: 85.0,
        isEnabled: true,
      );

      final sectorB = service.sectors.firstWhere((s) => s.id == 'setor_b');
      expect(sectorB.name, 'Setor B Editado');
      expect(sectorB.idealMoisture, 70.0);
      expect(sectorB.status, SectorStatus.irrigating);
      expect(service.activationHistory.any((ev) => ev['sectorId'] == 'setor_b'), isTrue);

      // Desativar a chave Liga/Desliga do setor desativa a operação sem excluir o setor
      await service.setSectorEnabled('setor_b', false);
      final sectorBDisabled = service.sectors.firstWhere((s) => s.id == 'setor_b');
      expect(sectorBDisabled.isEnabled, isFalse);
      expect(sectorBDisabled.status, SectorStatus.idle);
    });

    test('Gestão de múltiplos agendamentos (adicionar, editar, desativar e excluir)', () async {
      final initialCount = service.schedules.length;
      await service.addScheduleItem(
        time: '05:00',
        sectorIds: ['ALL'],
        sectorsLabel: 'Todos os Setores',
      );
      expect(service.schedules.length, initialCount + 1);
      final added = service.schedules.firstWhere((s) => s.time == '05:00');
      expect(added.isActive, isTrue);

      // Desativar agendamento (sem excluir)
      await service.toggleScheduleItemActive(added.id, false);
      final deactivated = service.schedules.firstWhere((s) => s.id == added.id);
      expect(deactivated.isActive, isFalse);

      // Editar agendamento
      await service.editScheduleItem(
        id: added.id,
        time: '08:45',
        sectorIds: ['setor_a'],
        sectorsLabel: 'Setor A',
        isActive: true,
      );
      final edited = service.schedules.firstWhere((s) => s.id == added.id);
      expect(edited.time, '08:45');
      expect(edited.sectorsLabel, 'Setor A');
      expect(edited.isActive, isTrue);

      // Excluir agendamento
      await service.deleteScheduleItem(added.id);
      expect(service.schedules.any((s) => s.id == added.id), isFalse);
    });
  });
}
