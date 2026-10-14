class ReportMetric {
  final String label;
  final String value;
  final String subtext;
  final String changeText;
  final bool isPositive;

  const ReportMetric({
    required this.label,
    required this.value,
    required this.subtext,
    required this.changeText,
    required this.isPositive,
  });
}

class ProductivityDataPoint {
  final String label;
  final double currentCycle;
  final double previousCycle;

  const ProductivityDataPoint({
    required this.label,
    required this.currentCycle,
    required this.previousCycle,
  });
}

class ExportableReport {
  final String id;
  final String title;
  final String formatAndPeriod;
  final String fileType; // pdf, csv

  const ExportableReport({
    required this.id,
    required this.title,
    required this.formatAndPeriod,
    required this.fileType,
  });
}
