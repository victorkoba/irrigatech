enum SectorStatus {
  irrigating,
  idle,
  error,
}

class SectorModel {
  final String id;
  final String name;
  final String region; // Norte, Leste, Sul, etc.
  final SectorStatus status; // irrigating = irrigação ativada automaticamente
  final bool isEnabled; // Chave Liga/Desliga do setor (ativo ou desativado para automação)
  final double idealMoisture; // % Umidade do solo ideal configurada para o setor
  final double minMoistureTrigger; // % Gatilho mínimo de automação do setor
  final double maxMoistureCutoff; // % Corte máximo de automação do setor
  final double flowRate; // m³/h (consumo de água)
  final double energyConsumption; // kWh (consumo de energia)
  final double moisture; // %
  final double temperature; // °C (exibida apenas no Monitoramento)
  final String? alertMessage;
  final String? activationReason;
  final DateTime? lastActivatedAt;

  const SectorModel({
    required this.id,
    required this.name,
    required this.region,
    required this.status,
    this.isEnabled = true,
    this.idealMoisture = 60.0,
    this.minMoistureTrigger = 35.0,
    this.maxMoistureCutoff = 75.0,
    required this.flowRate,
    this.energyConsumption = 0.0,
    required this.moisture,
    required this.temperature,
    this.alertMessage,
    this.activationReason,
    this.lastActivatedAt,
  });

  SectorModel copyWith({
    String? id,
    String? name,
    String? region,
    SectorStatus? status,
    bool? isEnabled,
    double? idealMoisture,
    double? minMoistureTrigger,
    double? maxMoistureCutoff,
    double? flowRate,
    double? energyConsumption,
    double? moisture,
    double? temperature,
    String? alertMessage,
    String? activationReason,
    DateTime? lastActivatedAt,
  }) {
    return SectorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      status: status ?? this.status,
      isEnabled: isEnabled ?? this.isEnabled,
      idealMoisture: idealMoisture ?? this.idealMoisture,
      minMoistureTrigger: minMoistureTrigger ?? this.minMoistureTrigger,
      maxMoistureCutoff: maxMoistureCutoff ?? this.maxMoistureCutoff,
      flowRate: flowRate ?? this.flowRate,
      energyConsumption: energyConsumption ?? this.energyConsumption,
      moisture: moisture ?? this.moisture,
      temperature: temperature ?? this.temperature,
      alertMessage: alertMessage ?? this.alertMessage,
      activationReason: activationReason ?? this.activationReason,
      lastActivatedAt: lastActivatedAt ?? this.lastActivatedAt,
    );
  }
}

class IrrigationScheduleItem {
  final String id;
  final String time;
  final List<String> sectorIds;
  final String sectorsLabel;
  final bool isActive;

  const IrrigationScheduleItem({
    required this.id,
    required this.time,
    required this.sectorIds,
    required this.sectorsLabel,
    this.isActive = true,
  });

  bool get isAllSectors => sectorIds.contains('ALL');

  IrrigationScheduleItem copyWith({
    String? id,
    String? time,
    List<String>? sectorIds,
    String? sectorsLabel,
    bool? isActive,
  }) {
    return IrrigationScheduleItem(
      id: id ?? this.id,
      time: time ?? this.time,
      sectorIds: sectorIds ?? this.sectorIds,
      sectorsLabel: sectorsLabel ?? this.sectorsLabel,
      isActive: isActive ?? this.isActive,
    );
  }
}
