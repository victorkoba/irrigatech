import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sector_model.dart';
import '../../services/irrigation_service.dart';

class IrrigationControlScreen extends StatefulWidget {
  const IrrigationControlScreen({super.key});

  @override
  State<IrrigationControlScreen> createState() => _IrrigationControlScreenState();
}

class _IrrigationControlScreenState extends State<IrrigationControlScreen> {
  late TextEditingController _minMoistureController;
  late TextEditingController _maxMoistureController;

  @override
  void initState() {
    super.initState();
    final service = context.read<IrrigationService>();
    _minMoistureController = TextEditingController(text: service.minMoistureTrigger.toInt().toString());
    _maxMoistureController = TextEditingController(text: service.maxMoistureCutoff.toInt().toString());
  }

  @override
  void dispose() {
    _minMoistureController.dispose();
    _maxMoistureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IrrigationService>();

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
            const Text(
              'Controle de Irrigação',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Stop Button (Stitch Red Big Button)
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.onError,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.power_settings_new_rounded, size: 24),
                label: const Text(
                  'DESLIGAR TUDO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: () {
                  service.emergencyStop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text('Comando de parada de emergência acionado! Todos os setores foram desligados.'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Modo de Operação (Segmented Control)
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
                    'MODO DE OPERAÇÃO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildModeButton(
                          'Automático',
                          service.operationMode == 'Automático',
                          () => service.setOperationMode('Automático'),
                        ),
                        _buildModeButton(
                          'Manual',
                          service.operationMode == 'Manual',
                          () => service.setOperationMode('Manual'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Controle por Setor List
            const Text(
              'CONTROLE POR SETOR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ...service.sectors.take(3).map((sector) => _buildSectorCard(sector, service)),
            const SizedBox(height: 16),

            // Parâmetros de Automação
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.primaryContainer, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Parâmetros de Automação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Min moisture
                  const Text(
                    'Umidade Mínima (Gatilho)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _minMoistureController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: '%',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Abaixo deste valor, a irrigação inicia automaticamente.',
                    style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  // Max moisture
                  const Text(
                    'Umidade Máxima (Corte)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _maxMoistureController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: '%',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryContainer, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ao atingir este valor, o sistema desliga.',
                    style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(color: AppColors.secondary),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: const Text('SALVAR PARÂMETROS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      onPressed: () {
                        final min = double.tryParse(_minMoistureController.text) ?? service.minMoistureTrigger;
                        final max = double.tryParse(_maxMoistureController.text) ?? service.maxMoistureCutoff;
                        service.updateParameters(min, max);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Parâmetros de automação salvos com sucesso!')),
                        );
                      },
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

  Widget _buildModeButton(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceCard : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isSelected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectorCard(SectorModel sector, IrrigationService service) {
    final isIrrigating = sector.status == SectorStatus.irrigating;
    final isError = sector.status == SectorStatus.error;

    Color stripColor = isIrrigating
        ? AppColors.primaryContainer
        : (isError ? AppColors.error : AppColors.outlineVariant);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorContainer.withValues(alpha: 0.25) : AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? AppColors.error.withValues(alpha: 0.4) : AppColors.outlineVariant,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(width: 5, height: 130, color: stripColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${sector.name} - ${sector.region}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (isIrrigating)
                              _buildStatusBadge('Irrigando', AppColors.primaryFixed, AppColors.primaryContainer, Icons.water_drop_rounded)
                            else if (isError)
                              _buildStatusBadge('Vazamento Detec.', AppColors.errorContainer, AppColors.error, Icons.warning_rounded)
                            else
                              _buildStatusBadge('Desligado', AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant, Icons.bedtime_rounded),
                          ],
                        ),
                        Switch(
                          value: isIrrigating,
                          activeThumbColor: AppColors.primaryContainer,
                          activeTrackColor: AppColors.primaryFixed,
                          inactiveThumbColor: AppColors.outline,
                          inactiveTrackColor: AppColors.surfaceContainerHigh,
                          onChanged: isError ? null : (_) => service.toggleSectorIrrigation(sector.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vazão',
                          style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                        ),
                        Text(
                          isError ? '-- m³/h' : '${sector.flowRate.toInt()} m³/h',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isIrrigating ? AppColors.secondary : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: sector.flowRate,
                      min: 0,
                      max: 100,
                      activeColor: AppColors.secondary,
                      inactiveColor: AppColors.surfaceContainerHigh,
                      onChanged: (isIrrigating && !isError)
                          ? (val) => service.setSectorFlowRate(sector.id, val)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color bg, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
        ],
      ),
    );
  }
}
