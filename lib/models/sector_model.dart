enum SectorStatus {
  irrigating,
  idle,
  error,
}

class SectorModel {
  final String id;
  final String name;
  final String region; // Norte, Leste, Sul, etc.
  final SectorStatus status;
  final double flowRate; // m³/h
  final double moisture; // %
  final double temperature; // °C
  final String? alertMessage;

  const SectorModel({
    required this.id,
    required this.name,
    required this.region,
    required this.status,
    required this.flowRate,
    required this.moisture,
    required this.temperature,
    this.alertMessage,
  });

  SectorModel copyWith({
    String? id,
    String? name,
    String? region,
    SectorStatus? status,
    double? flowRate,
    double? moisture,
    double? temperature,
    String? alertMessage,
  }) {
    return SectorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      status: status ?? this.status,
      flowRate: flowRate ?? this.flowRate,
      moisture: moisture ?? this.moisture,
      temperature: temperature ?? this.temperature,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }
}
