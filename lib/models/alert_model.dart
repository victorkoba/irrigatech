enum AlertSeverity { critical, warning, info }

class AlertModel {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final DateTime timestamp;

  const AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
  });
}
