import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../models/sector_model.dart';
import 'api_service.dart';

class IrrigationService extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _isSystemActive = true;
  String _operationMode = 'Automático';
  double _minMoistureTrigger = 30.0;
  double _maxMoistureCutoff = 75.0;
  String _selectedSectorId = 'setor_a';
  bool _isBackendOnline = false;
  String _nextIrrigationTime = '14:30';
  String _nextIrrigationSectors = 'Setor B, Setor D';
  double _dailyProgressPct = 65.0;
  List<SectorModel> _savedActiveSectors = [];

  // Descrição do Status Geral (salva e resgatada do banco de dados)
  String _statusCardDescription =
      'Estado em que o controle de irrigação está definido pelo cliente.';

  // Cards de Média Horária (resgatados de 1 em 1 hora do banco; estáticos durante 59 min)
  String _hourlyWaterValue = '45.0';
  String _hourlyEnergyValue = '42.0';
  String _hourlyEfficiencyValue = '94';
  String _hourlyWaterTrend = 'Média 1h • estático (59 min restantes)';
  String _hourlyEnergyTrend = 'Média 1h • estático (59 min restantes)';
  String _hourlyEfficiencyTrend = 'Temp. média 27.8°C • ciclo de 1h';
  int _hourlyMinutesRemaining = 59;
  DateTime _lastHourlySnapshotAt = DateTime.now();

  // Limites para geração de alerta crítico na Dashboard (Água, Energia, Temperatura)
  static const double waterAlertThreshold = 80.0; // m³/h
  static const double energyAlertThreshold = 100.0; // kWh
  static const double temperatureAlertThreshold = 35.0; // °C

  // Estado da Tela de Monitoramento (populado pelo script Python no banco de dados)
  bool _hasMonitoringData = true;
  double? _monitoringMoisture1h;
  int _monitoringMoistureMinutesRemaining = 59;
  double? _monitoringEnergy1h;
  int _monitoringEnergyMinutesRemaining = 59;
  double? _monitoringTemperature10m;
  int _monitoringTempMinutesRemaining = 10;
  double? _monitoringPrecipitation10m;
  int _monitoringPrecipMinutesRemaining = 10;
  List<Map<String, dynamic>> _monitoringHourlyChart = [];
  List<Map<String, dynamic>> _monitoringFullDayHistory = [];
  List<Map<String, dynamic>> _weeklyComparison = [];

  // Lista de Agendamentos de Irrigação (persistida no banco de dados)
  List<IrrigationScheduleItem> _schedules = [
    const IrrigationScheduleItem(
      id: 'sched_default_1',
      time: '14:30',
      sectorIds: ['setor_b', 'setor_d'],
      sectorsLabel: 'Setor B, Setor D',
      isActive: true,
    ),
    const IrrigationScheduleItem(
      id: 'sched_default_2',
      time: '06:00',
      sectorIds: ['ALL'],
      sectorsLabel: 'Todos os Setores',
      isActive: true,
    ),
  ];

  // Histórico de Acionamentos Automáticos para exibição nos Relatórios
  final List<Map<String, dynamic>> _activationHistory = [
    {
      'sectorId': 'setor_a',
      'sectorName': 'Setor A',
      'activatedAt': DateTime.now().subtract(const Duration(minutes: 25)),
      'reason': 'Automático: Umidade abaixo da ideal (45% < 60%)',
      'flowRate': 45.0,
    },
  ];

  List<SectorModel> _sectors = [
    const SectorModel(
      id: 'setor_a',
      name: 'Setor A',
      region: 'Norte',
      status: SectorStatus.irrigating,
      isEnabled: true,
      idealMoisture: 60.0,
      minMoistureTrigger: 35.0,
      maxMoistureCutoff: 75.0,
      flowRate: 45.0,
      energyConsumption: 42.0,
      moisture: 45.0,
      temperature: 28.0,
      activationReason: 'Automático: Umidade abaixo da ideal (45% < 60%)',
    ),
    const SectorModel(
      id: 'setor_b',
      name: 'Setor B',
      region: 'Leste',
      status: SectorStatus.idle,
      isEnabled: true,
      idealMoisture: 60.0,
      minMoistureTrigger: 35.0,
      maxMoistureCutoff: 75.0,
      flowRate: 0.0,
      energyConsumption: 0.0,
      moisture: 60.0,
      temperature: 26.5,
    ),
    const SectorModel(
      id: 'setor_c',
      name: 'Setor C',
      region: 'Sul',
      status: SectorStatus.error,
      isEnabled: true,
      idealMoisture: 60.0,
      minMoistureTrigger: 35.0,
      maxMoistureCutoff: 75.0,
      flowRate: 0.0,
      energyConsumption: 0.0,
      moisture: 18.0,
      temperature: 31.0,
      alertMessage: 'Vazamento Detectado',
    ),
    const SectorModel(
      id: 'setor_d',
      name: 'Setor D',
      region: 'Oeste',
      status: SectorStatus.idle,
      isEnabled: true,
      idealMoisture: 50.0,
      minMoistureTrigger: 30.0,
      maxMoistureCutoff: 75.0,
      flowRate: 0.0,
      energyConsumption: 0.0,
      moisture: 52.0,
      temperature: 27.0,
    ),
    const SectorModel(
      id: 'setor_e',
      name: 'Setor E',
      region: 'Central',
      status: SectorStatus.idle,
      isEnabled: true,
      idealMoisture: 55.0,
      minMoistureTrigger: 30.0,
      maxMoistureCutoff: 75.0,
      flowRate: 0.0,
      energyConsumption: 0.0,
      moisture: 58.0,
      temperature: 26.0,
    ),
  ];

  // Inicia vazia: alertas na Dashboard só entram quando algum setor monitorado
  // apresentar consumo/valor muito alto de água, energia e/ou temperatura.
  final List<AlertModel> _alerts = [];

  IrrigationService() {
    evaluateSectorAlerts();
    initBackendSync();
  }

  Future<void> initBackendSync() async {
    _isBackendOnline = await ApiService.isBackendOnline();
    if (_isBackendOnline) {
      final remoteSectors = await ApiService.fetchSectors();
      if (remoteSectors != null && remoteSectors.isNotEmpty) {
        _sectors = remoteSectors;
        if (!_sectors.any((s) => s.id == _selectedSectorId)) {
          _selectedSectorId = _sectors.first.id;
        }
      }
      final remoteSchedules = await ApiService.fetchSchedules();
      if (remoteSchedules != null) {
        _schedules = remoteSchedules;
        _syncNextScheduleLocal();
      }
      final dashboard = await ApiService.fetchDashboardSummary();
      if (dashboard != null) {
        _isSystemActive = dashboard['isSystemActive'] ?? _isSystemActive;
        if (dashboard['statusCardDescription'] != null) {
          _statusCardDescription = dashboard['statusCardDescription'];
        }
        if (dashboard['nextIrrigation'] != null) {
          final next = dashboard['nextIrrigation'];
          _nextIrrigationTime = next['time'] ?? _nextIrrigationTime;
          _nextIrrigationSectors = next['sectors'] ?? _nextIrrigationSectors;
          final prog = next['dailyProgressPct'];
          if (prog is num) _dailyProgressPct = prog.toDouble();
        }
        if (dashboard['kpis'] != null) {
          final kpis = dashboard['kpis'];
          if (kpis['waterConsumption'] != null) {
            _hourlyWaterValue = kpis['waterConsumption']['value']?.toString() ?? _hourlyWaterValue;
            _hourlyWaterTrend = kpis['waterConsumption']['trend']?.toString() ?? _hourlyWaterTrend;
          }
          if (kpis['energyConsumption'] != null) {
            _hourlyEnergyValue = kpis['energyConsumption']['value']?.toString() ?? _hourlyEnergyValue;
            _hourlyEnergyTrend = kpis['energyConsumption']['trend']?.toString() ?? _hourlyEnergyTrend;
          }
          if (kpis['efficiency'] != null) {
            _hourlyEfficiencyValue = kpis['efficiency']['value']?.toString() ?? _hourlyEfficiencyValue;
            _hourlyEfficiencyTrend = kpis['efficiency']['trend']?.toString() ?? _hourlyEfficiencyTrend;
          }
        }
        if (dashboard['hourlySnapshot'] != null) {
          final snap = dashboard['hourlySnapshot'];
          if (snap['minutesRemaining'] is num) {
            _hourlyMinutesRemaining = (snap['minutesRemaining'] as num).toInt();
          }
          if (snap['calculatedAt'] != null) {
            _lastHourlySnapshotAt = DateTime.tryParse(snap['calculatedAt'].toString()) ?? _lastHourlySnapshotAt;
          }
        }
        if (dashboard['criticalAlerts'] is List) {
          _alerts.clear();
          for (final item in dashboard['criticalAlerts']) {
            AlertSeverity sev = AlertSeverity.info;
            if (item['severity'] == 'critical') sev = AlertSeverity.critical;
            if (item['severity'] == 'warning') sev = AlertSeverity.warning;

            _alerts.add(AlertModel(
              id: item['id'],
              title: item['title'] ?? 'Alerta',
              description: item['description'] ?? '',
              severity: sev,
              timestamp: DateTime.tryParse(item['createdAt'] ?? item['timestamp'] ?? '') ?? DateTime.now(),
            ));
          }
        }
      }
      await refreshMonitoringData();
      notifyListeners();
    }
  }

  /// Sincroniza dados da tela de Monitoramento do banco de dados (populados pelo script Python)
  Future<void> refreshMonitoringData() async {
    if (!_isBackendOnline) {
      _isBackendOnline = await ApiService.isBackendOnline();
    }
    if (!_isBackendOnline) return;

    final remoteSectors = await ApiService.fetchSectors();
    if (remoteSectors != null && remoteSectors.isNotEmpty) {
      _sectors = remoteSectors;
      if (!_sectors.any((s) => s.id == _selectedSectorId)) {
        _selectedSectorId = _sectors.first.id;
      }
    }
    if (_sectors.isEmpty) return;

    final targetId = selectedSector.id;
    final summary = await ApiService.fetchSectorMonitoringSummary(targetId);
    if (summary != null) {
      _hasMonitoringData = summary['hasData'] == true;
      final m1h = summary['moisture1h']?['value'];
      _monitoringMoisture1h = m1h is num ? m1h.toDouble() : null;
      _monitoringMoistureMinutesRemaining = (summary['moisture1h']?['minutesRemaining'] as num?)?.toInt() ?? 59;

      final e1h = summary['energy1h']?['value'];
      _monitoringEnergy1h = e1h is num ? e1h.toDouble() : null;
      _monitoringEnergyMinutesRemaining = (summary['energy1h']?['minutesRemaining'] as num?)?.toInt() ?? 59;

      final t10m = summary['temperature10m']?['value'];
      _monitoringTemperature10m = t10m is num ? t10m.toDouble() : null;
      _monitoringTempMinutesRemaining = (summary['temperature10m']?['minutesRemaining'] as num?)?.toInt() ?? 10;

      final p10m = summary['precipitation10m']?['value'];
      _monitoringPrecipitation10m = p10m is num ? p10m.toDouble() : null;
      _monitoringPrecipMinutesRemaining = (summary['precipitation10m']?['minutesRemaining'] as num?)?.toInt() ?? 10;

      if (summary['hourlyChart'] is List) {
        _monitoringHourlyChart = (summary['hourlyChart'] as List).cast<Map<String, dynamic>>();
      } else {
        _monitoringHourlyChart = [];
      }

      if (summary['fullDayHistory'] is List) {
        _monitoringFullDayHistory = (summary['fullDayHistory'] as List).cast<Map<String, dynamic>>();
      } else {
        _monitoringFullDayHistory = [];
      }
    }

    final weekly = await ApiService.fetchWeeklyComparison();
    if (weekly != null) {
      _weeklyComparison = weekly;
    }
    notifyListeners();
  }

  /// Avalia automaticamente se a irrigação do setor deve ser ativada quando:
  /// - O setor está habilitado (`isEnabled == true`)
  /// - E a umidade está abaixo da ideal (`moisture < idealMoisture` ou `moisture <= minMoistureTrigger`)
  ///   OU a temperatura está muito elevada (`temperature >= 32.0°C`).
  /// Quando ativada, registra o evento no histórico de relatórios (`_activationHistory`).
  SectorModel _evaluateSectorAutomationLocal(SectorModel sector) {
    if (sector.status == SectorStatus.error) return sector;

    if (!sector.isEnabled) {
      if (sector.status == SectorStatus.irrigating) {
        return sector.copyWith(
          status: SectorStatus.idle,
          flowRate: 0.0,
          activationReason: '',
        );
      }
      return sector;
    }

    final isMoistureLow = sector.moisture < sector.idealMoisture || sector.moisture <= sector.minMoistureTrigger;
    final isTempHigh = sector.temperature >= 32.0;

    if (isMoistureLow || isTempHigh) {
      String reason;
      if (isMoistureLow && isTempHigh) {
        reason = 'Automático: Umidade (${sector.moisture.toInt()}% < ideal ${sector.idealMoisture.toInt()}%) e Temp. alta (${sector.temperature.toStringAsFixed(1)}°C)';
      } else if (isMoistureLow) {
        reason = 'Automático: Umidade abaixo da ideal (${sector.moisture.toInt()}% < ${sector.idealMoisture.toInt()}%)';
      } else {
        reason = 'Automático: Temperatura elevada (${sector.temperature.toStringAsFixed(1)}°C)';
      }

      final wasIrrigating = sector.status == SectorStatus.irrigating;
      final now = DateTime.now();
      final nextFlow = sector.flowRate > 0 ? sector.flowRate : 45.0;

      if (!wasIrrigating) {
        _isSystemActive = true;
        _activationHistory.insert(0, {
          'sectorId': sector.id,
          'sectorName': sector.name,
          'activatedAt': now,
          'reason': reason,
          'flowRate': nextFlow,
        });
      }

      return sector.copyWith(
        status: SectorStatus.irrigating,
        flowRate: nextFlow,
        activationReason: reason,
        lastActivatedAt: wasIrrigating ? (sector.lastActivatedAt ?? now) : now,
      );
    } else if (sector.moisture >= sector.idealMoisture &&
        sector.moisture >= sector.maxMoistureCutoff &&
        !isTempHigh &&
        sector.status == SectorStatus.irrigating) {
      return sector.copyWith(
        status: SectorStatus.idle,
        flowRate: 0.0,
        activationReason: '',
      );
    }

    return sector;
  }

  /// Avalia se algum setor do monitoramento possui consumo/valor muito alto
  /// de Água, Energia e/ou Temperatura. Apenas nessas condições o alerta entra na Dashboard.
  void evaluateSectorAlerts() {
    for (final sector in _sectors) {
      final isWaterHigh = sector.flowRate >= waterAlertThreshold;
      final isEnergyHigh = sector.energyConsumption >= energyAlertThreshold;
      final isTempHigh = sector.temperature >= temperatureAlertThreshold;
      final alertId = 'alert_threshold_${sector.id}';

      if (isWaterHigh || isEnergyHigh || isTempHigh) {
        final parts = <String>[];
        if (isWaterHigh) parts.add('Água: ${sector.flowRate.toStringAsFixed(1)} m³/h');
        if (isEnergyHigh) parts.add('Energia: ${sector.energyConsumption.toStringAsFixed(1)} kWh');
        if (isTempHigh) parts.add('Temperatura: ${sector.temperature.toStringAsFixed(1)}°C');

        final allThree = isWaterHigh && isEnergyHigh && isTempHigh;
        final title = allThree
            ? 'Alerta Crítico no ${sector.name}: Água, Energia e Temperatura elevadas'
            : 'Consumo/Valor muito alto no ${sector.name}';
        final desc = 'Monitoramento detectou índices acima do limite no ${sector.name}: ${parts.join(' | ')}.';
        final severity = (allThree || (isWaterHigh && isEnergyHigh) || sector.temperature >= 40.0)
            ? AlertSeverity.critical
            : AlertSeverity.warning;

        final existingIdx = _alerts.indexWhere((a) => a.id == alertId);
        final newAlert = AlertModel(
          id: alertId,
          title: title,
          description: desc,
          severity: severity,
          timestamp: DateTime.now(),
        );

        if (existingIdx >= 0) {
          _alerts[existingIdx] = newAlert;
        } else {
          _alerts.insert(0, newAlert);
        }
      } else {
        _alerts.removeWhere((a) => a.id == alertId);
      }
    }
  }

  /// Atualiza telemetria de um setor (ex.: via leitura de monitoramento) e reavalia automação + alertas
  void updateSectorTelemetry(
    String sectorId, {
    double? flowRate,
    double? energyConsumption,
    double? temperature,
    double? moisture,
  }) {
    _sectors = _sectors.map((s) {
      if (s.id == sectorId) {
        final updated = s.copyWith(
          flowRate: flowRate ?? s.flowRate,
          energyConsumption: energyConsumption ?? s.energyConsumption,
          temperature: temperature ?? s.temperature,
          moisture: moisture ?? s.moisture,
        );
        return _evaluateSectorAutomationLocal(updated);
      }
      return s;
    }).toList();
    evaluateSectorAlerts();
    notifyListeners();
  }

  // Getters
  int get currentTabIndex => _currentTabIndex;
  bool get isSystemActive => _isSystemActive || _sectors.any((s) => s.status == SectorStatus.irrigating);
  List<SectorModel> get savedActiveSectors => List.unmodifiable(_savedActiveSectors);
  String get operationMode => _operationMode;
  double get minMoistureTrigger => _minMoistureTrigger;
  double get maxMoistureCutoff => _maxMoistureCutoff;
  String get selectedSectorId => _selectedSectorId;
  bool get isBackendOnline => _isBackendOnline;
  List<SectorModel> get sectors => List.unmodifiable(_sectors);
  List<AlertModel> get alerts => List.unmodifiable(_alerts);
  List<IrrigationScheduleItem> get schedules => List.unmodifiable(_schedules);
  List<Map<String, dynamic>> get activationHistory => List.unmodifiable(_activationHistory);
  String get nextIrrigationTime => _nextIrrigationTime;
  String get nextIrrigationSectors => _nextIrrigationSectors;
  double get dailyProgressPct => _dailyProgressPct;
  String get statusCardDescription => _statusCardDescription;
  String get hourlyWaterValue => _hourlyWaterValue;
  String get hourlyEnergyValue => _hourlyEnergyValue;
  String get hourlyEfficiencyValue => _hourlyEfficiencyValue;
  String get hourlyWaterTrend => _hourlyWaterTrend;
  String get hourlyEnergyTrend => _hourlyEnergyTrend;
  String get hourlyEfficiencyTrend => _hourlyEfficiencyTrend;
  int get hourlyMinutesRemaining => _hourlyMinutesRemaining;
  DateTime get lastHourlySnapshotAt => _lastHourlySnapshotAt;

  // Monitoring Getters
  bool get hasMonitoringData => _hasMonitoringData;
  double? get monitoringMoisture1h => _monitoringMoisture1h;
  int get monitoringMoistureMinutesRemaining => _monitoringMoistureMinutesRemaining;
  double? get monitoringEnergy1h => _monitoringEnergy1h;
  int get monitoringEnergyMinutesRemaining => _monitoringEnergyMinutesRemaining;
  double? get monitoringTemperature10m => _monitoringTemperature10m;
  int get monitoringTempMinutesRemaining => _monitoringTempMinutesRemaining;
  double? get monitoringPrecipitation10m => _monitoringPrecipitation10m;
  int get monitoringPrecipMinutesRemaining => _monitoringPrecipMinutesRemaining;
  List<Map<String, dynamic>> get monitoringHourlyChart => List.unmodifiable(_monitoringHourlyChart);
  List<Map<String, dynamic>> get monitoringFullDayHistory => List.unmodifiable(_monitoringFullDayHistory);
  List<Map<String, dynamic>> get weeklyComparison => List.unmodifiable(_weeklyComparison);

  SectorModel get selectedSector {
    if (_sectors.isEmpty) {
      return const SectorModel(
        id: 'default',
        name: 'Setor Geral',
        region: 'Geral',
        status: SectorStatus.idle,
        flowRate: 0.0,
        moisture: 50.0,
        temperature: 25.0,
      );
    }
    return _sectors.firstWhere((s) => s.id == _selectedSectorId, orElse: () => _sectors.first);
  }

  // Actions
  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      if (index == 0) {
        initBackendSync();
      } else if (index == 2) {
        refreshMonitoringData();
      }
      notifyListeners();
    }
  }

  void setSelectedSector(String id) {
    if (_selectedSectorId != id) {
      _selectedSectorId = id;
      notifyListeners();
      refreshMonitoringData();
    }
  }

  void setOperationMode(String mode) {
    _operationMode = mode;
    notifyListeners();
    ApiService.setOperationMode(mode);
  }

  /// Alterna a chave Liga/Desliga (Ativo / Desativado) do setor na tela de Controle.
  /// Essa opção define se o setor está ativo no sistema e é independente do acionamento automático da irrigação.
  Future<void> setSectorEnabled(String sectorId, bool isEnabled) async {
    _sectors = _sectors.map((sector) {
      if (sector.id == sectorId) {
        final updated = sector.copyWith(isEnabled: isEnabled);
        return _evaluateSectorAutomationLocal(updated);
      }
      return sector;
    }).toList();

    evaluateSectorAlerts();
    notifyListeners();

    if (_isBackendOnline) {
      final remote = await ApiService.setSectorEnabled(sectorId, isEnabled);
      if (remote != null) {
        _sectors = _sectors.map((s) => s.id == sectorId ? remote : s).toList();
        evaluateSectorAlerts();
        notifyListeners();
      }
    }
  }

  void toggleSectorIrrigation(String sectorId) {
    bool turningOn = false;
    _sectors = _sectors.map((sector) {
      if (sector.id == sectorId) {
        if (sector.status == SectorStatus.error) {
          return sector;
        }
        final isCurrentlyOn = sector.status == SectorStatus.irrigating;
        if (!isCurrentlyOn) {
          turningOn = true;
          _activationHistory.insert(0, {
            'sectorId': sector.id,
            'sectorName': sector.name,
            'activatedAt': DateTime.now(),
            'reason': 'Acionamento de Irrigação (${sector.name})',
            'flowRate': 40.0,
          });
        }
        return sector.copyWith(
          status: isCurrentlyOn ? SectorStatus.idle : SectorStatus.irrigating,
          flowRate: isCurrentlyOn ? 0.0 : 40.0,
          lastActivatedAt: !isCurrentlyOn ? DateTime.now() : sector.lastActivatedAt,
        );
      }
      return sector;
    }).toList();

    if (turningOn || _sectors.any((s) => s.status == SectorStatus.irrigating)) {
      _isSystemActive = true;
    }

    evaluateSectorAlerts();
    notifyListeners();
    ApiService.toggleSector(sectorId);
  }

  void setSectorFlowRate(String sectorId, double rate) {
    _sectors = _sectors.map((sector) {
      if (sector.id == sectorId && sector.status == SectorStatus.irrigating) {
        return sector.copyWith(flowRate: rate);
      }
      return sector;
    }).toList();
    if (rate > 0) {
      _isSystemActive = true;
    }
    evaluateSectorAlerts();
    notifyListeners();
    ApiService.setFlowRate(sectorId, rate);
  }

  Future<SectorModel> addSector({
    required String name,
    required String region,
    double idealMoisture = 60.0,
    double minMoistureTrigger = 35.0,
    double maxMoistureCutoff = 75.0,
    bool isEnabled = true,
    double? moisture,
    double temperature = 25.0,
  }) async {
    final effectiveMoisture = moisture ?? idealMoisture;
    SectorModel? created;
    if (_isBackendOnline) {
      created = await ApiService.createSector(
        name: name,
        region: region,
        idealMoisture: idealMoisture,
        minMoistureTrigger: minMoistureTrigger,
        maxMoistureCutoff: maxMoistureCutoff,
        isEnabled: isEnabled,
        moisture: moisture,
      );
    }

    final cleanSlug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    SectorModel newSector = created ??
        SectorModel(
          id: 'setor_${cleanSlug}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          name: name,
          region: region,
          status: SectorStatus.idle,
          isEnabled: isEnabled,
          idealMoisture: idealMoisture,
          minMoistureTrigger: minMoistureTrigger,
          maxMoistureCutoff: maxMoistureCutoff,
          flowRate: 0.0,
          moisture: effectiveMoisture,
          temperature: temperature,
        );

    if (created == null && moisture != null && moisture < idealMoisture) {
      newSector = _evaluateSectorAutomationLocal(newSector);
    }

    _sectors = [..._sectors, newSector];
    evaluateSectorAlerts();
    notifyListeners();
    return newSector;
  }

  /// Edita os valores cadastrados de um setor existente e reavalia a automação
  Future<void> editSector({
    required String id,
    required String name,
    required String region,
    required double idealMoisture,
    required double minMoistureTrigger,
    required double maxMoistureCutoff,
    required bool isEnabled,
  }) async {
    _sectors = _sectors.map((s) {
      if (s.id == id) {
        final updated = s.copyWith(
          name: name,
          region: region,
          idealMoisture: idealMoisture,
          minMoistureTrigger: minMoistureTrigger,
          maxMoistureCutoff: maxMoistureCutoff,
          isEnabled: isEnabled,
        );
        return _evaluateSectorAutomationLocal(updated);
      }
      return s;
    }).toList();

    evaluateSectorAlerts();
    notifyListeners();

    if (_isBackendOnline) {
      final remote = await ApiService.updateSector(
        id: id,
        name: name,
        region: region,
        idealMoisture: idealMoisture,
        minMoistureTrigger: minMoistureTrigger,
        maxMoistureCutoff: maxMoistureCutoff,
        isEnabled: isEnabled,
      );
      if (remote != null) {
        _sectors = _sectors.map((s) => s.id == id ? remote : s).toList();
        evaluateSectorAlerts();
        notifyListeners();
      }
    }
  }

  /// Exclui um setor da aba Controle e garante que ele também suma na aba Monitoramento e no banco de dados
  Future<void> removeSector(String sectorId) async {
    _sectors = _sectors.where((s) => s.id != sectorId).toList();
    _savedActiveSectors = _savedActiveSectors.where((s) => s.id != sectorId).toList();
    _weeklyComparison = _weeklyComparison.where((w) => w['sectorId'] != sectorId).toList();
    _alerts.removeWhere((a) => a.id == 'alert_threshold_$sectorId');

    if (_selectedSectorId == sectorId) {
      _selectedSectorId = _sectors.isNotEmpty ? _sectors.first.id : 'default';
    }

    evaluateSectorAlerts();
    notifyListeners();

    if (_isBackendOnline) {
      await ApiService.deleteSector(sectorId);
      await refreshMonitoringData();
    }
  }

  Future<void> emergencyStop() async {
    _savedActiveSectors = _sectors
        .where((s) => s.status == SectorStatus.irrigating)
        .map((s) => s.copyWith())
        .toList();
    _isSystemActive = false;
    _sectors = _sectors.map((s) => s.copyWith(status: SectorStatus.idle, flowRate: 0.0, energyConsumption: 0.0)).toList();
    evaluateSectorAlerts();
    notifyListeners();
    await ApiService.emergencyStop();
  }

  Future<void> resumeSystem() async {
    _isSystemActive = true;

    final toRestore = _savedActiveSectors.isNotEmpty
        ? _savedActiveSectors
        : [
            _sectors.firstWhere(
              (s) => s.id == 'setor_a' && s.status != SectorStatus.error,
              orElse: () => _sectors.firstWhere(
                (s) => s.status != SectorStatus.error,
                orElse: () => _sectors.first,
              ),
            ).copyWith(flowRate: 45.0)
          ];

    _sectors = _sectors.map((sec) {
      final match = toRestore.cast<SectorModel?>().firstWhere(
            (r) => r?.id == sec.id,
            orElse: () => null,
          );
      if (match != null && sec.status != SectorStatus.error) {
        return sec.copyWith(
          status: SectorStatus.irrigating,
          flowRate: match.flowRate > 0 ? match.flowRate : 40.0,
        );
      }
      return sec;
    }).toList();

    _savedActiveSectors.clear();
    evaluateSectorAlerts();
    notifyListeners();
    await ApiService.resumeSystem();

    if (_isBackendOnline) {
      final remoteSectors = await ApiService.fetchSectors();
      if (remoteSectors != null && remoteSectors.isNotEmpty) {
        _sectors = remoteSectors;
        evaluateSectorAlerts();
        notifyListeners();
      }
    }
  }

  void updateParameters(double min, double max) {
    _minMoistureTrigger = min;
    _maxMoistureCutoff = max;
    notifyListeners();
    ApiService.updateParameters(min, max);
  }

  void dismissAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
    ApiService.resolveAlert(alertId);
  }

  Future<void> createAlert({
    required String title,
    required String description,
    AlertSeverity severity = AlertSeverity.warning,
    String? sectorId,
  }) async {
    final sevStr = severity == AlertSeverity.critical
        ? 'critical'
        : severity == AlertSeverity.warning
            ? 'warning'
            : 'info';
    final res = await ApiService.createAlert(
      title: title,
      description: description,
      severity: sevStr,
      sectorId: sectorId,
    );
    if (res != null) {
      _alerts.insert(
        0,
        AlertModel(
          id: res['id'],
          title: res['title'] ?? title,
          description: res['description'] ?? description,
          severity: severity,
          timestamp: DateTime.tryParse(res['createdAt'] ?? '') ?? DateTime.now(),
        ),
      );
      notifyListeners();
    } else {
      _alerts.insert(
        0,
        AlertModel(
          id: 'alert_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: description,
          severity: severity,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  // --- Gestão de Agendamentos de Irrigação ---

  void _syncNextScheduleLocal() {
    final activeList = _schedules.where((s) => s.isActive).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (activeList.isNotEmpty) {
      _nextIrrigationTime = activeList.first.time;
      _nextIrrigationSectors = activeList.first.sectorsLabel;
    } else {
      _nextIrrigationTime = '--:--';
      _nextIrrigationSectors = 'Nenhum agendamento ativo';
    }
  }

  void updateSchedule(String time, String sectors, {double dailyProgressPct = 65.0}) {
    _nextIrrigationTime = time;
    _nextIrrigationSectors = sectors;
    _dailyProgressPct = dailyProgressPct;
    notifyListeners();
    ApiService.updateSchedule(time, sectors, dailyProgressPct: dailyProgressPct);
  }

  Future<void> addScheduleItem({
    required String time,
    required List<String> sectorIds,
    required String sectorsLabel,
  }) async {
    IrrigationScheduleItem? created;
    if (_isBackendOnline) {
      created = await ApiService.createScheduleItem(
        time: time,
        sectorIds: sectorIds,
        sectorsLabel: sectorsLabel,
        isActive: true,
      );
    }

    final newItem = created ??
        IrrigationScheduleItem(
          id: 'sched_${DateTime.now().millisecondsSinceEpoch}',
          time: time,
          sectorIds: sectorIds,
          sectorsLabel: sectorsLabel,
          isActive: true,
        );

    _schedules = [..._schedules, newItem]..sort((a, b) => a.time.compareTo(b.time));
    _syncNextScheduleLocal();
    notifyListeners();
  }

  Future<void> editScheduleItem({
    required String id,
    required String time,
    required List<String> sectorIds,
    required String sectorsLabel,
    required bool isActive,
  }) async {
    _schedules = _schedules.map((s) {
      if (s.id == id) {
        return s.copyWith(
          time: time,
          sectorIds: sectorIds,
          sectorsLabel: sectorsLabel,
          isActive: isActive,
        );
      }
      return s;
    }).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    _syncNextScheduleLocal();
    notifyListeners();

    if (_isBackendOnline) {
      await ApiService.updateScheduleItem(
        id: id,
        time: time,
        sectorIds: sectorIds,
        sectorsLabel: sectorsLabel,
        isActive: isActive,
      );
    }
  }

  Future<void> toggleScheduleItemActive(String id, bool isActive) async {
    _schedules = _schedules.map((s) {
      if (s.id == id) {
        return s.copyWith(isActive: isActive);
      }
      return s;
    }).toList();

    _syncNextScheduleLocal();
    notifyListeners();

    if (_isBackendOnline) {
      await ApiService.toggleScheduleItem(id, isActive);
    }
  }

  Future<void> deleteScheduleItem(String id) async {
    _schedules = _schedules.where((s) => s.id != id).toList();
    _syncNextScheduleLocal();
    notifyListeners();

    if (_isBackendOnline) {
      await ApiService.deleteScheduleItem(id);
    }
  }
}
