import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../models/sector_model.dart';
import 'api_service.dart';

class IrrigationService extends ChangeNotifier {
  int _currentTabIndex = 0;
  bool _isSystemActive = true;
  String _operationMode = 'Automático'; // 'Automático' or 'Manual'
  double _minMoistureTrigger = 30.0;
  double _maxMoistureCutoff = 75.0;
  String _selectedSectorId = 'setor_a';
  bool _isBackendOnline = false;

  List<SectorModel> _sectors = [
    const SectorModel(
      id: 'setor_a',
      name: 'Setor A',
      region: 'Norte',
      status: SectorStatus.irrigating,
      flowRate: 45.0,
      moisture: 45.0,
      temperature: 28.0,
    ),
    const SectorModel(
      id: 'setor_b',
      name: 'Setor B',
      region: 'Leste',
      status: SectorStatus.idle,
      flowRate: 0.0,
      moisture: 60.0,
      temperature: 26.5,
    ),
    const SectorModel(
      id: 'setor_c',
      name: 'Setor C',
      region: 'Sul',
      status: SectorStatus.error,
      flowRate: 0.0,
      moisture: 18.0,
      temperature: 31.0,
      alertMessage: 'Vazamento Detectado',
    ),
    const SectorModel(
      id: 'setor_d',
      name: 'Setor D',
      region: 'Oeste',
      status: SectorStatus.idle,
      flowRate: 0.0,
      moisture: 52.0,
      temperature: 27.0,
    ),
    const SectorModel(
      id: 'setor_e',
      name: 'Setor E',
      region: 'Central',
      status: SectorStatus.idle,
      flowRate: 0.0,
      moisture: 58.0,
      temperature: 26.0,
    ),
  ];

  final List<AlertModel> _alerts = [
    AlertModel(
      id: 'alert_1',
      title: 'Umidade baixa no Setor A',
      description: 'Níveis abaixo de 15%. Irrigação de emergência recomendada.',
      severity: AlertSeverity.critical,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    AlertModel(
      id: 'alert_2',
      title: 'Vazamento detectado no Setor C',
      description: 'Pressão anormal na linha principal detectada há 10 min.',
      severity: AlertSeverity.warning,
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
  ];

  IrrigationService() {
    initBackendSync();
  }

  Future<void> initBackendSync() async {
    _isBackendOnline = await ApiService.isBackendOnline();
    if (_isBackendOnline) {
      final remoteSectors = await ApiService.fetchSectors();
      if (remoteSectors != null && remoteSectors.isNotEmpty) {
        _sectors = remoteSectors;
      }
      final dashboard = await ApiService.fetchDashboardSummary();
      if (dashboard != null) {
        _isSystemActive = dashboard['isSystemActive'] ?? _isSystemActive;
      }
      notifyListeners();
    }
  }

  // Getters
  int get currentTabIndex => _currentTabIndex;
  bool get isSystemActive => _isSystemActive;
  String get operationMode => _operationMode;
  double get minMoistureTrigger => _minMoistureTrigger;
  double get maxMoistureCutoff => _maxMoistureCutoff;
  String get selectedSectorId => _selectedSectorId;
  bool get isBackendOnline => _isBackendOnline;
  List<SectorModel> get sectors => List.unmodifiable(_sectors);
  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  SectorModel get selectedSector =>
      _sectors.firstWhere((s) => s.id == _selectedSectorId, orElse: () => _sectors.first);

  // Actions
  void setTabIndex(int index) {
    if (_currentTabIndex != index) {
      _currentTabIndex = index;
      notifyListeners();
    }
  }

  void setSelectedSector(String id) {
    if (_selectedSectorId != id) {
      _selectedSectorId = id;
      notifyListeners();
    }
  }

  void setOperationMode(String mode) {
    _operationMode = mode;
    notifyListeners();
    ApiService.setOperationMode(mode);
  }

  void toggleSectorIrrigation(String sectorId) {
    _sectors = _sectors.map((sector) {
      if (sector.id == sectorId) {
        if (sector.status == SectorStatus.error) {
          return sector;
        }
        final isCurrentlyOn = sector.status == SectorStatus.irrigating;
        return sector.copyWith(
          status: isCurrentlyOn ? SectorStatus.idle : SectorStatus.irrigating,
          flowRate: isCurrentlyOn ? 0.0 : 40.0,
        );
      }
      return sector;
    }).toList();
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
    notifyListeners();
    ApiService.setFlowRate(sectorId, rate);
  }

  void emergencyStop() {
    _isSystemActive = false;
    _sectors = _sectors.map((s) => s.copyWith(status: SectorStatus.idle, flowRate: 0.0)).toList();
    notifyListeners();
    ApiService.emergencyStop();
  }

  void resumeSystem() {
    _isSystemActive = true;
    notifyListeners();
    ApiService.resumeSystem();
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
  }
}
