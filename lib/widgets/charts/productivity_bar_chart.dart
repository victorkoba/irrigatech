import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';

class ProductivityBarChart extends StatelessWidget {
  final List<ProductivityDataPoint> data;

  const ProductivityBarChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const double maxVal = 90.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Produtividade Estimada',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Ciclo Atual vs. Ciclo Anterior (Sacas/ha)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildLegendItem('Atual', AppColors.primaryContainer),
                const SizedBox(width: 12),
                _buildLegendItem('Anterior', AppColors.outlineVariant),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y Axis Labels
              SizedBox(
                width: 28,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('80', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    Text('60', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    Text('40', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    Text('20', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    Text('0', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Bars area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.outlineVariant, width: 0.8),
                      bottom: BorderSide(color: AppColors.outlineVariant, width: 0.8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((item) {
                      final currentH = (item.currentCycle / maxVal) * 160;
                      final prevH = (item.previousCycle / maxVal) * 160;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Current cycle bar
                              Tooltip(
                                message: 'Atual: ${item.currentCycle.toInt()} sc/ha',
                                child: Container(
                                  width: 16,
                                  height: currentH,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryContainer,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Previous cycle bar
                              Tooltip(
                                message: 'Anterior: ${item.previousCycle.toInt()} sc/ha',
                                child: Container(
                                  width: 16,
                                  height: prevH,
                                  decoration: const BoxDecoration(
                                    color: AppColors.outlineVariant,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
