import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sector_model.dart';
import '../../services/api_service.dart';
import '../../services/file_downloader/file_downloader.dart';
import '../../services/irrigation_service.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<IrrigationService>().refreshMonitoringData();
      }
    });
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        context.read<IrrigationService>().refreshMonitoringData();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IrrigationService>();
    final selectedSector = service.selectedSector;
    final bool noDataInDb = service.isBackendOnline && !service.hasMonitoringData;

    final double? moistureVal = noDataInDb
        ? null
        : (service.monitoringMoisture1h ?? selectedSector.moisture);
    final double? tempVal = noDataInDb
        ? null
        : (service.monitoringTemperature10m ?? selectedSector.temperature);
    final double? precipVal = noDataInDb
        ? null
        : (service.monitoringPrecipitation10m ?? 2.0);
    final double? energyVal = noDataInDb
        ? null
        : (service.monitoringEnergy1h ??
            (selectedSector.energyConsumption > 0 ? selectedSector.energyConsumption : 18.5));

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryContainer),
            tooltip: 'Sincronizar com Banco de Dados',
            onPressed: () => service.refreshMonitoringData(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner informativo quando o banco foi limpo ou o script Python ainda não rodou
            if (noDataInDb) ...[
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: AppColors.error, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nenhum dado de telemetria encontrado no banco de dados. Execute o script Python (python scripts/populate_telemetry.py) para gerar leituras de 10s em 10s.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Sector Selector Pills (sincronizado com os setores do Controle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Setores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  '${service.sectors.where((s) => s.status == SectorStatus.irrigating).length} acionado(s) • ${service.sectors.length} no Controle',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (service.sectors.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: const Text(
                  'Nenhum setor cadastrado na aba Controle.',
                  style: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: service.sectors.map((sector) {
                    final isSelected = sector.id == selectedSector.id;
                    final isActive = sector.status == SectorStatus.irrigating;

                    // Setor acionado: cor mais forte e opacidade total (1.0)
                    // Setor não acionado: cor suave e opacidade reduzida para ficar menos visível
                    final double chipOpacity = isActive ? 1.0 : (isSelected ? 0.72 : 0.45);
                    final Color bgColor = isActive
                        ? AppColors.primaryContainer
                        : (isSelected ? AppColors.surfaceContainerHigh : AppColors.surfaceCard);
                    final Color fgColor = isActive
                        ? AppColors.onPrimary
                        : (isSelected ? AppColors.onSurface : AppColors.onSurfaceVariant);
                    final Color borderColor = isActive
                        ? (isSelected ? AppColors.secondary : AppColors.primaryContainer)
                        : (isSelected ? AppColors.primaryContainer.withValues(alpha: 0.6) : AppColors.outlineVariant);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Opacity(
                        opacity: chipOpacity,
                        child: ChoiceChip(
                          avatar: isActive
                              ? const Icon(Icons.water_drop_rounded, size: 15, color: AppColors.onPrimary)
                              : null,
                          label: Text(sector.name),
                          selected: isSelected,
                          selectedColor: bgColor,
                          backgroundColor: bgColor,
                          elevation: isActive ? 2 : 0,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive || isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: fgColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: borderColor,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          showCheckmark: false,
                          onSelected: (_) => service.setSelectedSector(sector.id),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),

            // 1. Umidade do Solo (Média da última 1 hora - igual à lógica da Dashboard)
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.water_drop_rounded, size: 18, color: AppColors.secondary),
                          SizedBox(width: 6),
                          Text(
                            'Umidade do Solo',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Média de 1 em 1 hora',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryContainer,
                            ),
                          ),
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
                          value: moistureVal != null ? (moistureVal / 100.0).clamp(0.0, 1.0) : 0.0,
                          strokeWidth: 10,
                          backgroundColor: AppColors.surfaceContainerHigh,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            moistureVal != null ? '${moistureVal.toStringAsFixed(0)}%' : '--%',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          const Text(
                            'média 1h',
                            style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primaryContainer),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          noDataInDb
                              ? 'Sem leituras no banco de dados'
                              : 'Média da última 1h • estático (${service.monitoringMoistureMinutesRemaining} min restantes)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Temperatura (10 em 10 min) & Precipitação (10 em 10 min)
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
                            Expanded(
                              child: Text(
                                'Temperatura',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tempVal != null ? '${tempVal.toStringAsFixed(0)}°C' : '--°C',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: AppColors.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                noDataInDb
                                    ? 'Sem dados (10m)'
                                    : 'Média 10 em 10 min (${service.monitoringTempMinutesRemaining}m)',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                              ),
                            ),
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
                            Expanded(
                              child: Text(
                                'Precipitação',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: precipVal != null ? precipVal.toStringAsFixed(1) : '--',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                              const TextSpan(
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
                        Text(
                          noDataInDb
                              ? 'Sem dados (10m)'
                              : 'Média 10 em 10 min (${service.monitoringPrecipMinutesRemaining}m)',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3. Nova Funcionalidade: Consumo de Energia do Setor (Dinâmico de 1 em 1 hora)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bolt_rounded, size: 20, color: AppColors.warningOrange),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Consumo de Energia',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          noDataInDb
                              ? 'Aguardando execução do script Python'
                              : 'Resgatado do banco • Atualiza de 1 em 1 hora (${service.monitoringEnergyMinutesRemaining} min restantes)',
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: energyVal != null ? energyVal.toStringAsFixed(1) : '--',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                            const TextSpan(
                              text: ' kWh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Média 1h',
                        style: TextStyle(fontSize: 10, color: AppColors.primaryContainer, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Histórico de Leituras Card (Umidade do Solo de 1 em 1 hora + Botão Histórico do Dia / Relatório)
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
                      Expanded(
                        child: Text(
                          'Histórico de Leituras',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                        ),
                      ),
                      Text(
                        '1 em 1 Hora (Umidade)',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 125,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: noDataInDb
                        ? const Center(
                            child: Text(
                              'Sem histórico de leituras no banco de dados.',
                              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _buildDynamicHourlyBars(service),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryContainer,
                        side: const BorderSide(color: AppColors.primaryContainer),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text(
                        'Ver Todo o Histórico do Dia',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showFullDayHistoryModal(context, service, selectedSector.name),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Comparativo Semanal Table Card (Dinâmico do Banco de Dados)
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
                  if (noDataInDb)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Sem dados comparativos no banco. Inicie o script Python para popular.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
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
                        ..._buildDynamicWeeklyRows(service),
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

  List<Widget> _buildDynamicHourlyBars(IrrigationService service) {
    final chartData = service.monitoringHourlyChart;
    if (chartData.isNotEmpty) {
      final items = chartData.length > 8 ? chartData.sublist(chartData.length - 8) : chartData;
      return List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;
        final val = (item['moisture'] as num?)?.toDouble() ?? 50.0;
        final label = isLast ? 'Agora' : (item['hourLabel']?.toString() ?? '${index}h');
        return _buildReadingBar(val, label, isCurrent: isLast);
      });
    }

    // Fallback offline quando o backend não está conectado (ex: testes de widget offline)
    return [
      _buildReadingBar(35, '00h'),
      _buildReadingBar(38, '03h'),
      _buildReadingBar(42, '06h'),
      _buildReadingBar(50, '09h'),
      _buildReadingBar(55, '12h'),
      _buildReadingBar(48, '15h'),
      _buildReadingBar(42, '18h'),
      _buildReadingBar(service.selectedSector.moisture, 'Agora', isCurrent: true),
    ];
  }

  List<TableRow> _buildDynamicWeeklyRows(IrrigationService service) {
    final dbRows = service.weeklyComparison;
    if (dbRows.isNotEmpty) {
      // Exibe apenas os setores que existem no Controle
      final activeIds = service.sectors.map((s) => s.id).toSet();
      final filtered = dbRows.where((r) => activeIds.contains(r['sectorId'])).toList();
      if (filtered.isNotEmpty) {
        return filtered.map((r) {
          final name = r['sector']?.toString() ?? 'Setor';
          final lastW = r['lastWeek']?.toString() ?? '0L';
          final thisW = r['thisWeek']?.toString() ?? '0L';
          final variation = r['variation']?.toString() ?? '0%';
          final status = r['status']?.toString() ?? 'reduction';
          return _buildTableRow(
            name,
            lastW,
            thisW,
            variation,
            isDecrease: status == 'reduction' || variation.startsWith('-'),
          );
        }).toList();
      }
    }

    return service.sectors.map((s) {
      final prev = (s.moisture * 2.2).clamp(30.0, 200.0).toInt();
      final curr = (s.moisture * 2.0).clamp(25.0, 190.0).toInt();
      final diff = curr - prev;
      final diffPct = (diff.abs() / (prev == 0 ? 1 : prev) * 100.0).toStringAsFixed(1);
      final isDecrease = diff <= 0;
      return _buildTableRow(
        s.name,
        '$prev m³',
        '$curr m³',
        '${isDecrease ? "-" : "+"}$diffPct%',
        isDecrease: isDecrease,
      );
    }).toList();
  }

  void _showFullDayHistoryModal(BuildContext context, IrrigationService service, String sectorName) {
    final history = service.monitoringFullDayHistory;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Histórico do Dia — $sectorName',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Leituras de umidade do solo, temperatura, precipitação e energia registradas hoje no banco de dados. Caso deseje mais detalhes ou períodos anteriores, baixe o relatório completo abaixo.',
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: history.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Nenhuma leitura detalhada encontrada no banco para hoje. Execute o script Python (scripts/populate_telemetry.py) para popular.',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = history[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryFixed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item['time']?.toString() ?? '--:--',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              'Umidade: ${item['moisture']}% • Energia: ${item['energyConsumption']} kWh',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Temp: ${item['temperature']}°C • Precip: ${item['precipitation']} mm • Água: ${item['waterConsumption']} L',
                              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Baixar Relatório (CSV)'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _downloadFullHistoryCsv(context, service, sectorName);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFullHistoryCsv(BuildContext context, IrrigationService service, String sectorName) async {
    String? csvContent = await ApiService.downloadReport('water_report');
    if (csvContent == null || csvContent.isEmpty) {
      final rows = <String>[
        'Horario,Setor,Umidade_Pct,Temperatura_C,Precipitacao_mm,Energia_kWh,Agua_L',
      ];
      for (final item in service.monitoringFullDayHistory) {
        rows.add(
          '${item['time'] ?? ''},$sectorName,${item['moisture'] ?? 0},${item['temperature'] ?? 0},${item['precipitation'] ?? 0},${item['energyConsumption'] ?? 0},${item['waterConsumption'] ?? 0}',
        );
      }
      csvContent = rows.join('\n');
    }

    const fileName = 'historico_monitoramento_irrigacao.csv';
    FileDownloader.download(fileName, csvContent);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryContainer,
        content: Text('Relatório completo "$fileName" baixado com sucesso!'),
      ),
    );
  }

  Widget _buildReadingBar(double value, String label, {bool isCurrent = false}) {
    final normalizedHeight = ((value.clamp(0.0, 100.0)) / 100.0) * 78.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${value.toInt()}%',
          style: TextStyle(
            fontSize: 8,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppColors.secondary : AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 14,
          height: normalizedHeight < 6 ? 6 : normalizedHeight,
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
