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
              'Controle',
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
            const SizedBox(height: 4),
            const Text(
              'Gerenciamento automatizado por setor. Caso um setor não precise operar, basta desativá-lo na chave Liga/Desliga.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Botão de Parada de Emergência / Reativar Tudo
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: service.isSystemActive ? AppColors.error : AppColors.primaryContainer,
                  foregroundColor: service.isSystemActive ? AppColors.onError : AppColors.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  service.isSystemActive ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                  size: 24,
                ),
                label: Text(
                  service.isSystemActive ? 'DESLIGAR TUDO' : 'REATIVAR SISTEMA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: () {
                  if (service.isSystemActive) {
                    service.emergencyStop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text('Comando de parada de emergência acionado! Todos os setores foram desligados.'),
                      ),
                    );
                  } else {
                    service.resumeSystem();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primaryContainer,
                        content: Text('Sistema de irrigação reativado com sucesso!'),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Cabeçalho de Controle por Setor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'CONTROLE E AUTOMAÇÃO POR SETOR',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${service.sectors.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryContainer,
                    side: const BorderSide(color: AppColors.primaryContainer, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Novo Setor',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _openSectorFormDialog(context, service),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'A irrigação é ativada automaticamente quando a umidade do solo fica abaixo da ideal ou a temperatura sobe muito (registrando o evento no Relatório).',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 12),

            // Lista de Setores
            ...service.sectors.map((sector) => _buildSectorCard(context, sector, service)),
            const SizedBox(height: 16),

            // Card de Agendamentos de Irrigação
            _buildSchedulesCard(context, service),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorCard(BuildContext context, SectorModel sector, IrrigationService service) {
    final isIrrigating = sector.status == SectorStatus.irrigating;
    final isError = sector.status == SectorStatus.error;
    final isEnabled = sector.isEnabled;

    Color stripColor;
    if (isError) {
      stripColor = AppColors.error;
    } else if (!isEnabled) {
      stripColor = AppColors.outlineVariant;
    } else if (isIrrigating) {
      stripColor = AppColors.primaryContainer;
    } else {
      stripColor = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isError
            ? AppColors.errorContainer.withValues(alpha: 0.25)
            : (!isEnabled ? AppColors.surfaceContainerLow : AppColors.surfaceCard),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError
              ? AppColors.error.withValues(alpha: 0.4)
              : (isIrrigating ? AppColors.primaryContainer.withValues(alpha: 0.5) : AppColors.outlineVariant),
          width: isIrrigating ? 1.4 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: stripColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Topo: Nome, Status de Ativação, Editar, Excluir e Switch Liga/Desliga do Setor
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${sector.name} - ${sector.region}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isEnabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    // Badge de Setor Ativo / Desativado (chave Liga/Desliga)
                                    _buildStatusBadge(
                                      isEnabled ? 'Setor Ativo' : 'Setor Desativado',
                                      isEnabled ? AppColors.primaryFixed : AppColors.surfaceContainerHigh,
                                      isEnabled ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                                      isEnabled ? Icons.check_circle_outline_rounded : Icons.power_off_outlined,
                                    ),
                                    // Badge de Estado da Irrigação Automática
                                    if (isError)
                                      _buildStatusBadge(
                                        sector.alertMessage ?? 'Vazamento Detec.',
                                        AppColors.errorContainer,
                                        AppColors.error,
                                        Icons.warning_rounded,
                                      )
                                    else if (isIrrigating && isEnabled)
                                      _buildStatusBadge(
                                        'Irrigação Ativada',
                                        AppColors.secondary.withValues(alpha: 0.15),
                                        AppColors.secondary,
                                        Icons.water_drop_rounded,
                                      )
                                    else if (isEnabled)
                                      _buildStatusBadge(
                                        'Em Monitoramento',
                                        AppColors.surfaceContainerHigh,
                                        AppColors.onSurfaceVariant,
                                        Icons.sensors_rounded,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Botões Editar, Excluir e Switch Liga/Desliga do Setor
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryContainer, size: 20),
                                tooltip: 'Editar Valores do Setor',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _openSectorFormDialog(context, service, existingSector: sector),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                tooltip: 'Excluir Setor',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _openDeleteSectorConfirmDialog(context, service, sector),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: isEnabled,
                                    activeThumbColor: AppColors.primaryContainer,
                                    activeTrackColor: AppColors.primaryFixed,
                                    inactiveThumbColor: AppColors.outline,
                                    inactiveTrackColor: AppColors.surfaceContainerHigh,
                                    onChanged: (val) => service.setSectorEnabled(sector.id, val),
                                  ),
                                  Text(
                                    isEnabled ? 'Ligado' : 'Desligado',
                                    style: const TextStyle(fontSize: 9, color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Parâmetros de Automação cadastrados neste Setor
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _buildParamInfo('Umidade Ideal', '${sector.idealMoisture.toInt()}%'),
                            _buildParamInfo('Gatilho Mín.', '${sector.minMoistureTrigger.toInt()}%'),
                            _buildParamInfo('Corte Máx.', '${sector.maxMoistureCutoff.toInt()}%'),
                            _buildParamInfo('Umidade Atual', '${sector.moisture.toInt()}%'),
                          ],
                        ),
                      ),

                      // Aviso quando a Irrigação Automática foi ativada (e registrada no Relatório)
                      if (isIrrigating && isEnabled) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primaryContainer),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${sector.activationReason ?? "Irrigação acionada automaticamente"} • Registrado no Relatório de Eventos',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                      // Controle de Vazão
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vazão de Irrigação',
                            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                          ),
                          Text(
                            isError ? '-- m³/h' : '${sector.flowRate.toInt()} m³/h',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isIrrigating ? AppColors.secondary : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: sector.flowRate.clamp(0.0, 100.0),
                        min: 0,
                        max: 100,
                        activeColor: AppColors.secondary,
                        inactiveColor: AppColors.surfaceContainerHigh,
                        onChanged: (isIrrigating && isEnabled && !isError)
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
      ),
    );
  }

  Widget _buildParamInfo(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryContainer,
          ),
        ),
      ],
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

  // --- Card de Agendamentos de Irrigação ---
  Widget _buildSchedulesCard(BuildContext context, IrrigationService service) {
    final schedules = service.schedules;

    return Container(
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.edit_calendar_rounded, color: AppColors.primaryContainer, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Agendamento de Irrigação',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_alarm_rounded, size: 16),
                label: const Text(
                  'Novo Agendamento',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _openScheduleFormDialog(context, service),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Opção para acionar a irrigação automaticamente em todos os setores ou em setores específicos em um determinado horário programado.',
            style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          if (schedules.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'Nenhum agendamento cadastrado. Clique em "Novo Agendamento" acima.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
              ),
            )
          else
            ...schedules.map((sched) => _buildScheduleListItem(context, service, sched)),
        ],
      ),
    );
  }

  Widget _buildScheduleListItem(
    BuildContext context,
    IrrigationService service,
    IrrigationScheduleItem sched,
  ) {
    final isActive = sched.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceContainerLow : AppColors.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? AppColors.primaryContainer.withValues(alpha: 0.35) : AppColors.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 18,
                      color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      sched.time,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.primaryFixed : AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'Ativo' : 'Desativado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  sched.sectorsLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Switch para Ativar / Desativar o agendamento (diferente de excluir)
          Tooltip(
            message: isActive ? 'Desativar Agendamento' : 'Ativar Agendamento',
            child: Switch(
              value: isActive,
              activeThumbColor: AppColors.primaryContainer,
              activeTrackColor: AppColors.primaryFixed,
              onChanged: (val) {
                service.toggleScheduleItemActive(sched.id, val);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? 'Agendamento das ${sched.time} ativado!'
                          : 'Agendamento das ${sched.time} desativado (mantido na lista).',
                    ),
                  ),
                );
              },
            ),
          ),
          // Botão Editar Agendamento
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryContainer),
            tooltip: 'Editar Agendamento',
            visualDensity: VisualDensity.compact,
            onPressed: () => _openScheduleFormDialog(context, service, existingSchedule: sched),
          ),
          // Botão Excluir Agendamento
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
            tooltip: 'Excluir Agendamento',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              service.deleteScheduleItem(sched.id);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.error,
                  content: Text('Agendamento das ${sched.time} excluído.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Modal de Confirmação para Deletar Setor ---
  void _openDeleteSectorConfirmDialog(
    BuildContext context,
    IrrigationService service,
    SectorModel sector,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirmar Exclusão de Setor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Deseja realmente excluir o setor "${sector.name} (${sector.region})"?\n\nAo confirmar, este setor será removido permanentemente do Controle, do Monitoramento e do banco de dados.',
          style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Sim, Excluir Setor'),
            onPressed: () {
              service.removeSector(sector.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.error,
                  content: Text('${sector.name} excluído com sucesso do Controle e do Monitoramento.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Modal de Cadastro e Edição de Setor (com Umidade Ideal + Parâmetros de Automação por Setor, sem perguntar Temperatura) ---
  void _openSectorFormDialog(
    BuildContext context,
    IrrigationService service, {
    SectorModel? existingSector,
  }) {
    final isEditing = existingSector != null;
    final nextLetter = String.fromCharCode(65 + (service.sectors.length % 26));
    final nameCtrl = TextEditingController(
      text: isEditing ? existingSector.name : 'Setor $nextLetter',
    );
    final regionCtrl = TextEditingController(
      text: isEditing ? existingSector.region : 'Talhão ${service.sectors.length + 1}',
    );
    double idealMoisture = isEditing ? existingSector.idealMoisture : 60.0;
    double minMoistureTrigger = isEditing ? existingSector.minMoistureTrigger : 35.0;
    double maxMoistureCutoff = isEditing ? existingSector.maxMoistureCutoff : 75.0;
    bool isEnabled = isEditing ? existingSector.isEnabled : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                color: AppColors.primaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEditing ? 'Editar ${existingSector.name}' : 'Adicionar Novo Setor',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Altere os dados e parâmetros de automação deste setor. A temperatura do setor é monitorada automaticamente pelos sensores na aba Monitoramento.'
                      : 'Informe a identificação, a umidade ideal do solo e os parâmetros de automação deste setor. A temperatura será exibida automaticamente no Monitoramento.',
                  style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nome do Setor',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ex: Setor F ou Pivô 4',
                    prefixIcon: const Icon(Icons.grid_view_rounded, size: 20, color: AppColors.primaryContainer),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Região / Talhão',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: regionCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ex: Noroeste ou Talhão 6 (Soja)',
                    prefixIcon: const Icon(Icons.place_rounded, size: 20, color: AppColors.primaryContainer),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),

                // Umidade do Solo Ideal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Umidade do Solo Ideal',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                    ),
                    Text(
                      '${idealMoisture.toInt()}%',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primaryContainer),
                    ),
                  ],
                ),
                const Text(
                  'Se a umidade ficar abaixo do ideal ou a temperatura subir muito, a irrigação ativa automaticamente.',
                  style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                ),
                Slider(
                  value: idealMoisture.clamp(20.0, 95.0),
                  min: 20.0,
                  max: 95.0,
                  divisions: 75,
                  activeColor: AppColors.primaryContainer,
                  onChanged: (val) {
                    setModalState(() {
                      idealMoisture = val;
                    });
                  },
                ),
                const Divider(),

                // Parâmetros de Automação do Setor
                const Text(
                  'PARÂMETROS DE AUTOMAÇÃO DO SETOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),

                // Gatilho Mínimo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Umidade Mínima (Gatilho)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                    Text(
                      '${minMoistureTrigger.toInt()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.secondary),
                    ),
                  ],
                ),
                Slider(
                  value: minMoistureTrigger.clamp(10.0, 80.0),
                  min: 10.0,
                  max: 80.0,
                  divisions: 70,
                  activeColor: AppColors.secondary,
                  onChanged: (val) {
                    setModalState(() {
                      minMoistureTrigger = val;
                    });
                  },
                ),

                // Corte Máximo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Umidade Máxima (Corte)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                    ),
                    Text(
                      '${maxMoistureCutoff.toInt()}%',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryContainer),
                    ),
                  ],
                ),
                Slider(
                  value: maxMoistureCutoff.clamp(40.0, 100.0),
                  min: 40.0,
                  max: 100.0,
                  divisions: 60,
                  activeColor: AppColors.primaryContainer,
                  onChanged: (val) {
                    setModalState(() {
                      maxMoistureCutoff = val;
                    });
                  },
                ),

                // Switch Setor Ativo / Desativado
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Setor Ativo para Automação',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Desative caso este setor não precise operar no momento.',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: isEnabled,
                  activeThumbColor: AppColors.primaryContainer,
                  onChanged: (val) {
                    setModalState(() {
                      isEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryContainer),
              icon: Icon(isEditing ? Icons.save_rounded : Icons.check_rounded, size: 18),
              label: Text(isEditing ? 'Salvar Alterações' : 'Cadastrar Setor'),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final region = regionCtrl.text.trim();
                if (name.isEmpty || region.isEmpty) return;

                Navigator.pop(ctx);
                if (isEditing) {
                  await service.editSector(
                    id: existingSector.id,
                    name: name,
                    region: region,
                    idealMoisture: idealMoisture,
                    minMoistureTrigger: minMoistureTrigger,
                    maxMoistureCutoff: maxMoistureCutoff,
                    isEnabled: isEnabled,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryContainer,
                      content: Text('$name atualizado com sucesso! (Umidade ideal: ${idealMoisture.toInt()}%)'),
                    ),
                  );
                } else {
                  final created = await service.addSector(
                    name: name,
                    region: region,
                    idealMoisture: idealMoisture,
                    minMoistureTrigger: minMoistureTrigger,
                    maxMoistureCutoff: maxMoistureCutoff,
                    isEnabled: isEnabled,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primaryContainer,
                      content: Text('${created.name} (${created.region}) cadastrado com umidade ideal de ${idealMoisture.toInt()}%!'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Modal de Adicionar / Editar Agendamento (com Relógio showTimePicker e Select estilo HTML com Todos ou Individual) ---
  void _openScheduleFormDialog(
    BuildContext context,
    IrrigationService service, {
    IrrigationScheduleItem? existingSchedule,
  }) {
    final isEditing = existingSchedule != null;

    // Parseia horário inicial para o relógio (TimeOfDay)
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 0);
    if (isEditing && existingSchedule.time.contains(':')) {
      final parts = existingSchedule.time.split(':');
      final h = int.tryParse(parts[0]) ?? 6;
      final m = int.tryParse(parts[1]) ?? 0;
      selectedTime = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }

    // Seleção de setores: 'ALL' (Todos os Setores) ou IDs individuais
    bool selectAllSectors = isEditing ? existingSchedule.isAllSectors : true;
    final Set<String> selectedSectorIds = {};
    if (isEditing && !existingSchedule.isAllSectors) {
      selectedSectorIds.addAll(existingSchedule.sectorIds);
    } else {
      for (final s in service.sectors) {
        selectedSectorIds.add(s.id);
      }
    }
    bool isDropdownOpen = false;
    bool isActive = isEditing ? existingSchedule.isActive : true;

    String formatTimeOfDay(TimeOfDay tod) {
      final hh = tod.hour.toString().padLeft(2, '0');
      final mm = tod.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    String buildSelectionSummary() {
      if (selectAllSectors || selectedSectorIds.length == service.sectors.length) {
        return 'Todos os Setores (${service.sectors.length})';
      }
      if (selectedSectorIds.isEmpty) {
        return 'Selecione os setores...';
      }
      final names = service.sectors
          .where((s) => selectedSectorIds.contains(s.id))
          .map((s) => s.name)
          .toList();
      return names.join(', ');
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar_rounded, color: AppColors.primaryContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEditing ? 'Editar Agendamento' : 'Novo Agendamento de Irrigação',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha o horário no relógio e selecione se deseja acionar todos os setores ou setores específicos.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),

                // 1. Seletor de Horário via Relógio (showTimePicker)
                const Text(
                  'Horário Programado (Relógio)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      helpText: 'SELECIONE O HORÁRIO DA IRRIGAÇÃO',
                      cancelText: 'CANCELAR',
                      confirmText: 'CONFIRMAR',
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primaryContainer, width: 1.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: AppColors.primaryContainer, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              formatTimeOfDay(selectedTime),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryContainer,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Abrir Relógio',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Select de Setores (estilo <select> HTML com "Todos os Setores" ou seleção individual)
                const Text(
                  'Selecionar Setores',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
                ),
                const SizedBox(height: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setModalState(() {
                      isDropdownOpen = !isDropdownOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outline, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            buildSelectionSummary(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          isDropdownOpen ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                          color: AppColors.primaryContainer,
                        ),
                      ],
                    ),
                  ),
                ),

                // Lista suspensa do Select (opção "Todos os Setores" + cada setor individualmente)
                if (isDropdownOpen) ...[
                  const SizedBox(height: 4),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 210),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CheckboxListTile(
                            dense: true,
                            activeColor: AppColors.primaryContainer,
                            title: const Text(
                              'Selecionar Todos os Setores',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            value: selectAllSectors,
                            onChanged: (val) {
                              setModalState(() {
                                selectAllSectors = val ?? false;
                                if (selectAllSectors) {
                                  selectedSectorIds
                                    ..clear()
                                    ..addAll(service.sectors.map((s) => s.id));
                                } else {
                                  selectedSectorIds.clear();
                                }
                              });
                            },
                          ),
                          const Divider(height: 1),
                          ...service.sectors.map((sec) {
                            final isChecked = selectAllSectors || selectedSectorIds.contains(sec.id);
                            return CheckboxListTile(
                              dense: true,
                              activeColor: AppColors.primaryContainer,
                              title: Text(
                                '${sec.name} (${sec.region})',
                                style: const TextStyle(fontSize: 12),
                              ),
                              value: isChecked,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedSectorIds.add(sec.id);
                                    if (selectedSectorIds.length == service.sectors.length) {
                                      selectAllSectors = true;
                                    }
                                  } else {
                                    selectAllSectors = false;
                                    selectedSectorIds.remove(sec.id);
                                  }
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Switch Ativar / Desativar agendamento
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text(
                    'Agendamento Ativo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Você pode desativar temporariamente sem excluir.',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: isActive,
                  activeThumbColor: AppColors.primaryContainer,
                  onChanged: (val) {
                    setModalState(() {
                      isActive = val;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryContainer),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text(isEditing ? 'Salvar Alterações' : 'Adicionar Agendamento'),
              onPressed: () async {
                if (!selectAllSectors && selectedSectorIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.error,
                      content: Text('Selecione pelo menos um setor ou marque "Todos os Setores".'),
                    ),
                  );
                  return;
                }

                final formattedTime = formatTimeOfDay(selectedTime);
                final isAll = selectAllSectors || selectedSectorIds.length == service.sectors.length;
                final List<String> finalIds = isAll ? ['ALL'] : selectedSectorIds.toList();
                final String finalLabel = isAll
                    ? 'Todos os Setores'
                    : service.sectors
                        .where((s) => selectedSectorIds.contains(s.id))
                        .map((s) => s.name)
                        .join(', ');

                Navigator.pop(ctx);
                if (isEditing) {
                  await service.editScheduleItem(
                    id: existingSchedule.id,
                    time: formattedTime,
                    sectorIds: finalIds,
                    sectorsLabel: finalLabel,
                    isActive: isActive,
                  );
                } else {
                  await service.addScheduleItem(
                    time: formattedTime,
                    sectorIds: finalIds,
                    sectorsLabel: finalLabel,
                  );
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primaryContainer,
                    content: Text(
                      isEditing
                          ? 'Agendamento atualizado para às $formattedTime ($finalLabel).'
                          : 'Agendamento adicionado para às $formattedTime ($finalLabel).',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
