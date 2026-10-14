import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';
import '../../widgets/charts/productivity_bar_chart.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productivityData = [
      const ProductivityDataPoint(label: 'Talhão A', currentCycle: 68, previousCycle: 60),
      const ProductivityDataPoint(label: 'Talhão B', currentCycle: 74, previousCycle: 64),
      const ProductivityDataPoint(label: 'Talhão C', currentCycle: 56, previousCycle: 52),
      const ProductivityDataPoint(label: 'Talhão D', currentCycle: 78, previousCycle: 68),
    ];

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumo Mensal
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
                        'Resumo Mensal',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                      ),
                      Icon(Icons.insights_rounded, color: AppColors.secondary, size: 22),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    label: 'ECONOMIA DE ÁGUA',
                    percentage: '24%',
                    subtext: '12.500 m³ poupados',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryItem(
                    label: 'ECONOMIA DE ENERGIA',
                    percentage: '18%',
                    subtext: '4.200 kWh reduzidos',
                    color: AppColors.warningOrange,
                  ),
                  const SizedBox(height: 12),
                  // ROI Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ROI ESTIMADO (MENSAL)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: AppColors.primaryFixedDim,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'R\$ 8.450',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryFixed,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Retorno sobre otimização',
                          style: TextStyle(fontSize: 12, color: AppColors.onPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Produtividade Estimada (Bar Chart)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: ProductivityBarChart(data: productivityData),
            ),
            const SizedBox(height: 16),

            // Conformidade Ambiental Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conformidade Ambiental',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  const Text(
                    'Métricas de sustentabilidade',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_rounded, color: AppColors.primaryContainer, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Certificado Verde',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryContainer),
                            ),
                            Text(
                              'STATUS: ATIVO',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryContainer),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Meta de Redução de Água (Ano)',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      Text(
                        '85%',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: 0.85,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceContainerLowest,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Relatórios para Exportar
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 12),
                  _buildExportItem(
                    title: 'Consumo de Água',
                    sub: 'PDF, CSV • Últimos 30 dias',
                    icon: Icons.water_drop_rounded,
                    iconBg: AppColors.secondaryFixed,
                    iconColor: AppColors.secondary,
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download do relatório de água iniciado...')),
                      );
                    },
                  ),
                  const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                  _buildExportItem(
                    title: 'Histórico de Eventos',
                    sub: 'CSV • Todos os sensores',
                    icon: Icons.history_rounded,
                    iconBg: AppColors.surfaceContainerHighest,
                    iconColor: AppColors.onSurface,
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download do histórico de eventos iniciado...')),
                      );
                    },
                  ),
                  const Divider(height: 16, color: AppColors.surfaceContainerHigh),
                  _buildExportItem(
                    title: 'Eficiência Energética',
                    sub: 'PDF • Relatório Detalhado',
                    icon: Icons.bolt_rounded,
                    iconBg: AppColors.tertiaryFixed,
                    iconColor: AppColors.warningOrange,
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Download do relatório de energia iniciado...')),
                      );
                    },
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

  Widget _buildSummaryItem({
    required String label,
    required String percentage,
    required String subtext,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: const [
                  Icon(Icons.arrow_downward_rounded, size: 14, color: AppColors.primaryContainer),
                  Text(
                    'vs. Mês Ant.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildExportItem({
    required String title,
    required String sub,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onDownload,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
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
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: AppColors.outline, size: 22),
          onPressed: onDownload,
        ),
      ],
    );
  }
}
