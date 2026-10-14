import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/irrigation_service.dart';
import '../../widgets/shared/alert_tile.dart';
import '../../widgets/shared/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IrrigationService>();
    final alerts = service.alerts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.agriculture_rounded, color: AppColors.primaryContainer, size: 28),
            SizedBox(width: 10),
            Text(
              'IrrigaTech',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryContainer,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.onSurface, size: 24),
                if (alerts.isNotEmpty)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Você tem ${alerts.length} alertas pendentes.')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Geral Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATUS GERAL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.isSystemActive ? 'SISTEMA ATIVO' : 'SISTEMA SUSPENSO',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: service.isSystemActive ? AppColors.primaryContainer : AppColors.error,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: service.isSystemActive
                          ? AppColors.primaryContainer
                          : AppColors.errorContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (service.isSystemActive
                                  ? AppColors.primaryContainer
                                  : AppColors.error)
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      service.isSystemActive ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                      color: service.isSystemActive
                          ? AppColors.onPrimary
                          : AppColors.onErrorContainer,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Alertas Críticos Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alertas Críticos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${alerts.length} Urgentes',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum alerta crítico no momento.',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
                      ),
                    )
                  else
                    ...alerts.map((alert) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AlertTile(
                          alert: alert,
                          onVerify: () {
                            service.setTabIndex(2); // Jump to Irrigation Control
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Próxima Irrigação Card (Stitch Dark Green Banner)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      Icons.schedule_rounded,
                      size: 100,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRÓXIMA IRRIGAÇÃO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryFixedDim,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '14:30',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Setores B e D (Milho)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryFixed,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Progresso Diário',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryFixedDim,
                            ),
                          ),
                          Text(
                            '65%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryFixed),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // KPI Cards Grid
            MetricCard(
              title: 'Consumo de Água',
              value: '1.2k',
              unit: 'm³/h',
              trendText: '-5% vs ontem',
              icon: Icons.water_drop_rounded,
              iconColor: AppColors.secondary,
              trendColor: AppColors.secondary,
              trendIcon: Icons.trending_down_rounded,
            ),
            const SizedBox(height: 12),
            MetricCard(
              title: 'Consumo de Energia',
              value: '450',
              unit: 'kWh',
              trendText: '+2% vs ontem',
              icon: Icons.bolt_rounded,
              iconColor: AppColors.warningOrange,
              trendColor: AppColors.warningOrange,
              trendIcon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 12),
            MetricCard(
              title: 'Eficiência Geral',
              value: '94',
              unit: '%',
              trendText: 'Excelente',
              icon: Icons.speed_rounded,
              iconColor: AppColors.primaryContainer,
              trendColor: AppColors.primaryContainer,
              trendIcon: Icons.trending_up_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
