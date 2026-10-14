import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/irrigation_service.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IrrigationService>();
    final selectedSector = service.selectedSector;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.agriculture_rounded, color: AppColors.primaryContainer, size: 28),
            SizedBox(width: 10),
            Text(
              'Monitoramento',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sector Selector Pills
            const Text(
              'Setores',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: service.sectors.map((sector) {
                  final isSelected = sector.id == service.selectedSectorId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(sector.name),
                      selected: isSelected,
                      selectedColor: AppColors.primaryContainer,
                      backgroundColor: AppColors.surfaceCard,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : AppColors.outlineVariant,
                        ),
                      ),
                      showCheckmark: false,
                      onSelected: (_) => service.setSelectedSector(sector.id),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Bento Grid: Real-time Sensor Cards
            // 1. Umidade do Solo (Gauge Card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Icon(Icons.water_drop_rounded, size: 18, color: AppColors.secondary),
                      SizedBox(width: 6),
                      Text(
                        'Umidade do Solo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: selectedSector.moisture / 100.0,
                          strokeWidth: 10,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${selectedSector.moisture.toInt()}%',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const Text(
                            'atual',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_drop_up_rounded, size: 20, color: AppColors.primaryContainer),
                      Text(
                        '+2% nas últimas 2h',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Temperatura & Precipitação Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.thermostat_rounded, size: 18, color: AppColors.warningOrange),
                            SizedBox(width: 6),
                            Text(
                              'Temperatura',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${selectedSector.temperature.toInt()}°C',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            Icon(Icons.trending_flat_rounded, size: 16, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 4),
                            Text('Estável', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.outlineVariant, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.cloud_queue_rounded, size: 18, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Text(
                              'Precipitação',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '2',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                              TextSpan(
                                text: ' mm',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Previsão: 5mm hoje',
                          style: TextStyle(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Histórico de Leituras Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Histórico de Leituras',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                      ),
                      Text(
                        '24 Horas (Umidade)',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildReadingBar(35, '00h'),
                        _buildReadingBar(38, '03h'),
                        _buildReadingBar(42, '06h'),
                        _buildReadingBar(50, '09h'),
                        _buildReadingBar(55, '12h'),
                        _buildReadingBar(48, '15h'),
                        _buildReadingBar(42, '18h'),
                        _buildReadingBar(45, 'Agora', isCurrent: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Comparativo Semanal Table Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comparativo Semanal (Uso de Água)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(1.2),
                      1: FlexColumnWidth(1.3),
                      2: FlexColumnWidth(1.3),
                      3: FlexColumnWidth(1.3),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.outlineVariant, width: 1)),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Setor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Sem. Passada', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Esta Semana', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Variação', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
                          ),
                        ],
                      ),
                      _buildTableRow('Setor A', '120 m³', '105 m³', '-12.5%', isDecrease: true),
                      _buildTableRow('Setor B', '95 m³', '102 m³', '+7.3%', isDecrease: false),
                      _buildTableRow('Setor C', '150 m³', '148 m³', '-1.3%', isDecrease: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingBar(double value, String label, {bool isCurrent = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: (value / 60.0) * 80,
          decoration: BoxDecoration(
            color: isCurrent ? AppColors.secondary : AppColors.secondaryFixedDim,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppColors.secondary : AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(String sector, String prev, String curr, String change, {required bool isDecrease}) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh, width: 0.8)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(sector, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(prev, style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(curr, style: const TextStyle(fontSize: 12, color: AppColors.onSurface)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDecrease ? AppColors.primaryFixed : AppColors.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              change,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDecrease ? AppColors.primaryContainer : AppColors.onErrorContainer,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
