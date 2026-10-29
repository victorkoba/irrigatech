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
              'Dashboard',
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
                SnackBar(content: Text('Você tem ${alerts.length} alertas críticos no momento.')),
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
            // 1. Status Geral Banner (com descrição do controle definido pelo cliente)
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
                  Expanded(
                    child: Column(
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
                        const SizedBox(height: 6),
                        Text(
                          service.statusCardDescription,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
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

            // 2. Alertas Críticos Condicionais (Apenas Água, Energia e Temperatura muito altos nos Setores)
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
                          color: alerts.isNotEmpty
                              ? AppColors.errorContainer
                              : AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          alerts.isNotEmpty ? '${alerts.length} Urgentes' : 'Normal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: alerts.isNotEmpty
                                ? AppColors.onErrorContainer
                                : AppColors.primaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Exibidos apenas quando algum setor do monitoramento registrar consumo/valor muito alto de água, energia e/ou temperatura.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nenhum alerta crítico no momento. Todos os setores operam dentro dos limites normais.',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                      ),
                    )
                  else
                    ...alerts.map((alert) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AlertTile(
                          alert: alert,
                          onVerify: () {
                            service.setTabIndex(1); // Jump to Monitoring
                          },
                          onDismiss: () {
                            service.dismissAlert(alert.id);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.primaryContainer,
                                content: Text('Alerta "${alert.title}" resolvido no banco de dados.'),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Próxima Irrigação Card (Resgatado do Banco de Dados / Configurado no Controle)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          InkWell(
                            onTap: () {
                              service.setTabIndex(2); // Jump to Irrigation Control
                            },
                            child: Row(
                              children: const [
                                Icon(Icons.edit_calendar_rounded, size: 14, color: AppColors.primaryFixed),
                                SizedBox(width: 4),
                                Text(
                                  'Agendar no Controle',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryFixed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.nextIrrigationTime,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.nextIrrigationSectors,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryFixed,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progresso Diário',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryFixedDim,
                            ),
                          ),
                          Text(
                            '${service.dailyProgressPct.toInt()}%',
                            style: const TextStyle(
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
                          value: (service.dailyProgressPct / 100.0).clamp(0.0, 1.0),
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

            // 4. Demais Cards (Média Consolidada de 1 em 1 hora do Banco de Dados — Estático por 59 min)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'MÉDIA CONSOLIDADA DO BANCO (1 EM 1 HORA)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Estático (${service.hourlyMinutesRemaining} min)',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            MetricCard(
              title: 'Consumo de Água',
              value: service.hourlyWaterValue,
              unit: 'm³/h',
              trendText: service.hourlyWaterTrend,
              icon: Icons.water_drop_rounded,
              iconColor: AppColors.secondary,
              trendColor: AppColors.secondary,
              trendIcon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 12),
            MetricCard(
              title: 'Consumo de Energia',
              value: service.hourlyEnergyValue,
              unit: 'kWh',
              trendText: service.hourlyEnergyTrend,
              icon: Icons.bolt_rounded,
              iconColor: AppColors.warningOrange,
              trendColor: AppColors.warningOrange,
              trendIcon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 12),
            MetricCard(
              title: 'Eficiência Geral',
              value: service.hourlyEfficiencyValue,
              unit: '%',
              trendText: service.hourlyEfficiencyTrend,
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
