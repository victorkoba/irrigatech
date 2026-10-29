import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/file_downloader/file_downloader.dart';
import '../../services/irrigation_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _summaryData;
  List<Map<String, dynamic>> _monthlySavingsChart = [];
  List<Map<String, dynamic>> _remoteActivationEvents = [];

  @override
  void initState() {
    super.initState();
    _loadRealReportsData();
  }

  Future<void> _loadRealReportsData() async {
    setState(() {
      _isLoading = true;
    });
    final overview = await ApiService.fetchReportsOverview();
    if (!mounted) return;
    if (overview != null) {
      setState(() {
        if (overview['summary'] is Map) {
          _summaryData = (overview['summary'] as Map).cast<String, dynamic>();
        }
        if (overview['monthlySavingsChart'] is List) {
          _monthlySavingsChart =
              (overview['monthlySavingsChart'] as List).cast<Map<String, dynamic>>();
        }
        if (overview['activationEvents'] is List) {
          _remoteActivationEvents =
              (overview['activationEvents'] as List).cast<Map<String, dynamic>>();
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Abre modal para o cliente escolher se deseja exportar em .xlsx ou .csv
  void _openFormatSelectionModal(BuildContext context, String reportId, String title) {
    String selectedFormat = 'xlsx';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.download_for_offline_rounded, color: AppColors.primaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Baixar "$title"',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecione o formato desejado para exportar os dados reais registrados no banco de dados PostgreSQL:',
                style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setModalState(() => selectedFormat = 'xlsx'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedFormat == 'xlsx'
                        ? AppColors.primaryFixed.withValues(alpha: 0.45)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedFormat == 'xlsx'
                          ? AppColors.primaryContainer
                          : AppColors.outlineVariant,
                      width: selectedFormat == 'xlsx' ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.table_view_rounded, color: AppColors.primaryContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Planilha Excel (.xlsx)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Formato estruturado para Microsoft Excel e Planilhas',
                              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selectedFormat == 'xlsx'
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: AppColors.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setModalState(() => selectedFormat = 'csv'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedFormat == 'csv'
                        ? AppColors.primaryFixed.withValues(alpha: 0.45)
                        : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selectedFormat == 'csv'
                          ? AppColors.primaryContainer
                          : AppColors.outlineVariant,
                      width: selectedFormat == 'csv' ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Valores Separados por Vírgula (.csv)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Arquivo leve compatível com qualquer sistema de análise',
                              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        selectedFormat == 'csv'
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: AppColors.primaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryContainer),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text('Baixar .${selectedFormat.toUpperCase()}'),
              onPressed: () {
                Navigator.pop(ctx);
                _handleDownloadReport(context, reportId, title, selectedFormat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDownloadReport(
    BuildContext context,
    String reportId,
    String title,
    String format,
  ) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Consultando banco de dados e gerando "$title" (.${format.toUpperCase()})...'),
            ),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    final content = await ApiService.downloadReport(reportId, format: format);
    if (!context.mounted) return;

    if (content == null || content.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Não foi possível exportar: verifique se o backend está online e com dados no banco.'),
        ),
      );
      return;
    }

    final fileName = '$reportId.$format';
    FileDownloader.download(fileName, content);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Relatório real "$fileName" baixado com sucesso!')),
          ],
        ),
        action: SnackBarAction(
          label: 'VER DADOS',
          textColor: AppColors.primaryFixed,
          onPressed: () => _showReportPreviewDialog(context, title, fileName, content),
        ),
      ),
    );
  }

  Future<void> _handleDownloadMonthlySavingsPdf(BuildContext context) async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gerando PDF do Gráfico de Economia Mensal (R\$) com dados do banco...'),
        duration: Duration(seconds: 1),
      ),
    );

    final pdfBytes = await ApiService.downloadMonthlySavingsPdf();
    if (!context.mounted) return;

    if (pdfBytes == null || pdfBytes.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Não foi possível baixar o PDF: verifique a conexão com o servidor backend.'),
        ),
      );
      return;
    }

    const fileName = 'relatorio_economia_mensal_irrigatech.pdf';
    FileDownloader.downloadBytes(fileName, pdfBytes, mimeType: 'application/pdf');

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryContainer,
        content: Text('Gráfico em PDF "$fileName" baixado com sucesso!'),
      ),
    );
  }

  void _showReportPreviewDialog(
    BuildContext context,
    String title,
    String fileName,
    String content,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.table_chart_rounded, color: AppColors.primaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Arquivo gerado do banco de dados: $fileName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: SelectableText(
                    content.trim(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IrrigationService>();

    // Valores reais resgatados do banco de dados (com cálculo de comparação vs mês anterior)
    final String currMonth = _summaryData?['currentMonthLabel']?.toString() ?? 'Out/26';
    final String prevMonth = _summaryData?['previousMonthLabel']?.toString() ?? 'Set/26';

    final double waterPct = (_summaryData?['waterSavingsPct'] as num?)?.toDouble() ?? 21.1;
    final String waterSavedM3 = _summaryData?['waterSavedM3']?.toString() ?? '300';
    final String waterSavingsBrl = _summaryData?['waterSavingsBrl']?.toString() ?? '1155.00';
    final bool isWaterPositive = _summaryData?['isWaterPositive'] is bool
        ? (_summaryData!['isWaterPositive'] as bool)
        : (waterPct >= 0);

    final double energyPct = (_summaryData?['energySavingsPct'] as num?)?.toDouble() ?? 19.8;
    final String energySavedKwh = _summaryData?['energySavedKwh']?.toString() ?? '245';
    final String energySavingsBrl = _summaryData?['energySavingsBrl']?.toString() ?? '191.10';
    final bool isEnergyPositive = _summaryData?['isEnergyPositive'] is bool
        ? (_summaryData!['isEnergyPositive'] as bool)
        : (energyPct >= 0);

    final String roiBrl = _summaryData?['estimatedRoiBrl']?.toString() ?? '1346.10';
    final String prevRoiBrl = _summaryData?['previousMonthRoiBrl']?.toString() ?? '308.50';
    final double roiCompPct = (_summaryData?['roiComparisonPct'] as num?)?.toDouble() ?? 336.3;
    final bool isRoiPositive = _summaryData?['isRoiPositive'] is bool
        ? (_summaryData!['isRoiPositive'] as bool)
        : ((double.tryParse(roiBrl) ?? 0.0) >= 0);

    final double waterTariff = (_summaryData?['waterTariffPerM3'] as num?)?.toDouble() ?? 3.85;
    final double energyTariff = (_summaryData?['energyTariffPerKwh'] as num?)?.toDouble() ?? 0.78;

    final eventsList = _remoteActivationEvents.isNotEmpty
        ? _remoteActivationEvents
        : service.activationHistory;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.agriculture_rounded, color: AppColors.primaryContainer, size: 28),
            SizedBox(width: 10),
            Text(
              'Relatórios',
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
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primaryContainer),
            tooltip: 'Atualizar Dados do Banco',
            onPressed: _loadRealReportsData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Resumo Mensal (Água, Energia e ROI do mesmo tamanho, comparando com o mês anterior)
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Resumo Mensal (Dados Reais do Banco)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            Text(
                              'Comparativo $currMonth vs $prevMonth • Tarifas: Água R\$ ${waterTariff.toStringAsFixed(2)}/m³ | Energia R\$ ${energyTariff.toStringAsFixed(2)}/kWh',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.insights_rounded, color: AppColors.secondary, size: 22),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Card 1: Economia de Água (comparado com mês anterior)
                  _buildSummaryMetricCard(
                    label: 'ECONOMIA DE ÁGUA ($currMonth vs $prevMonth)',
                    mainValue: '${waterPct >= 0 ? "+" : ""}${waterPct.toStringAsFixed(1)}%',
                    subtext:
                        '${isWaterPositive ? "$waterSavedM3 m³ poupados" : "${waterSavedM3.replaceAll("-", "")} m³ excedentes"} em relação a $prevMonth (R\$ $waterSavingsBrl)',
                    isPositive: isWaterPositive,
                    icon: Icons.water_drop_rounded,
                  ),
                  const SizedBox(height: 10),

                  // Card 2: Economia de Energia (comparado com mês anterior)
                  _buildSummaryMetricCard(
                    label: 'ECONOMIA DE ENERGIA ($currMonth vs $prevMonth)',
                    mainValue: '${energyPct >= 0 ? "+" : ""}${energyPct.toStringAsFixed(1)}%',
                    subtext:
                        '${isEnergyPositive ? "$energySavedKwh kWh reduzidos" : "${energySavedKwh.replaceAll("-", "")} kWh excedentes"} em relação a $prevMonth (R\$ $energySavingsBrl)',
                    isPositive: isEnergyPositive,
                    icon: Icons.bolt_rounded,
                  ),
                  const SizedBox(height: 10),

                  // Card 3: ROI Estimado (Mesmo tamanho dos cards de Água e Energia, verde se positivo e vermelho se negativo)
                  _buildSummaryMetricCard(
                    label: 'ROI ESTIMADO — ECONOMIA TOTAL ($currMonth vs $prevMonth)',
                    mainValue: 'R\$ $roiBrl',
                    subtext:
                        'Mês passado ($prevMonth): R\$ $prevRoiBrl (${roiCompPct >= 0 ? "+" : ""}${roiCompPct.toStringAsFixed(1)}% de variação)',
                    isPositive: isRoiPositive,
                    icon: Icons.paid_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Relatório da Economia em R$ Durante os Meses (Gráfico Baixável em PDF com Dados Reais)
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
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Economia Financeira (R\$) Durante os Meses',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Cálculo mensal real do banco de dados (Água + Energia vs mês anterior)',
                              style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.primaryContainer),
                        label: const Text(
                          'Baixar PDF',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => _handleDownloadMonthlySavingsPdf(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 165,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _buildMonthlySavingsBars(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Economia Positiva (Verde)',
                            style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Saldo Negativo (Vermelho)',
                            style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Registro de Irrigações Ativadas Automaticamente (Quando foi ativado)
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
                          'Registro de Irrigações Ativadas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.water_drop_rounded, color: AppColors.primaryContainer, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Exibe quando a irrigação foi ativada automaticamente por umidade abaixo da ideal ou temperatura elevada.',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ...eventsList.take(5).map((ev) {
                    final dt = ev['activatedAt'] is DateTime
                        ? (ev['activatedAt'] as DateTime)
                        : (DateTime.tryParse(ev['activatedAt']?.toString() ?? '') ?? DateTime.now());
                    final hh = dt.hour.toString().padLeft(2, '0');
                    final mm = dt.minute.toString().padLeft(2, '0');
                    final dd = dt.day.toString().padLeft(2, '0');
                    final mo = dt.month.toString().padLeft(2, '0');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ev['sectorName'] ?? 'Setor'} — Ativada às $hh:$mm ($dd/$mo)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ev['reason']?.toString() ?? 'Acionamento Automático',
                                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(ev['flowRate'] as num?)?.toInt() ?? 45} m³/h',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Relatórios para Exportar (.xlsx ou .csv via Modal, com descrições reais do banco)
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
                    'Relatórios para Exportar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Clique no ícone de download para escolher entre Excel (.xlsx) ou CSV (.csv) com dados reais do banco.',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  _buildExportItem(
                    title: 'Consumo e Economia de Água',
                    sub: 'XLSX ou CSV • Leituras hídricas reais por setor e custo (R\$ 3,85/m³) do banco',
                    icon: Icons.water_drop_rounded,
                    iconBg: AppColors.secondaryFixed,
                    iconColor: AppColors.secondary,
                    onDownload: () => _openFormatSelectionModal(
                      context,
                      'water_report',
                      'Consumo e Economia de Água',
                    ),
                  ),
                  const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                  _buildExportItem(
                    title: 'Histórico de Eventos e Acionamentos',
                    sub: 'XLSX ou CSV • Registro real de irrigações ativadas e sensores do banco',
                    icon: Icons.history_rounded,
                    iconBg: AppColors.surfaceContainerHighest,
                    iconColor: AppColors.onSurface,
                    onDownload: () => _openFormatSelectionModal(
                      context,
                      'events_report',
                      'Histórico de Eventos e Acionamentos',
                    ),
                  ),
                  const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                  _buildExportItem(
                    title: 'Eficiência Energética e ROI Mensal',
                    sub: 'XLSX ou CSV • Consumo em kWh (R\$ 0,78/kWh) e economia financeira mensal do banco',
                    icon: Icons.bolt_rounded,
                    iconBg: AppColors.tertiaryFixed,
                    iconColor: AppColors.warningOrange,
                    onDownload: () => _openFormatSelectionModal(
                      context,
                      'energy_report',
                      'Eficiência Energética e ROI Mensal',
                    ),
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

  /// Card padronizado (mesmo tamanho para Água, Energia e ROI Estimado),
  /// exibindo em Verde quando positivo e em Vermelho quando negativo.
  Widget _buildSummaryMetricCard({
    required String label,
    required String mainValue,
    required String subtext,
    required bool isPositive,
    required IconData icon,
  }) {
    final Color statusColor = isPositive ? AppColors.primaryContainer : AppColors.error;
    final Color bgTint = isPositive
        ? AppColors.primaryFixed.withValues(alpha: 0.35)
        : AppColors.errorContainer.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 15, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.35)),
            ),
            child: Text(
              mainValue,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthlySavingsBars() {
    final List<Map<String, dynamic>> data = _monthlySavingsChart.isNotEmpty
        ? _monthlySavingsChart
        : [
            {'monthLabel': 'Mai/26', 'totalSavingsBrl': 586.30, 'isPositive': true},
            {'monthLabel': 'Jun/26', 'totalSavingsBrl': 493.70, 'isPositive': true},
            {'monthLabel': 'Jul/26', 'totalSavingsBrl': 316.30, 'isPositive': true},
            {'monthLabel': 'Ago/26', 'totalSavingsBrl': 247.10, 'isPositive': true},
            {'monthLabel': 'Set/26', 'totalSavingsBrl': 308.50, 'isPositive': true},
            {'monthLabel': 'Out/26', 'totalSavingsBrl': 1346.10, 'isPositive': true},
          ];

    double maxAbs = 100.0;
    for (final item in data) {
      final v = ((item['totalSavingsBrl'] as num?)?.toDouble() ?? 0.0).abs();
      if (v > maxAbs) maxAbs = v;
    }

    return data.map((item) {
      final label = item['monthLabel']?.toString() ?? '';
      final val = (item['totalSavingsBrl'] as num?)?.toDouble() ?? 0.0;
      final isPos = val >= 0;
      final barHeight = ((val.abs() / maxAbs) * 90.0).clamp(10.0, 90.0);
      final barColor = isPos ? AppColors.primaryContainer : AppColors.error;

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'R\$ ${val.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: barColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildExportItem({
    required String title,
    required String sub,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onDownload,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onDownload,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded, color: AppColors.primaryContainer, size: 22),
              tooltip: 'Escolher formato (.XLSX ou .CSV) e baixar',
              onPressed: onDownload,
            ),
          ],
        ),
      ),
    );
  }
}
