const db = require('../config/db');

const fallbackMonthlySummary = {
  waterSavingsPct: 24,
  waterSavedM3: '12.500',
  energySavingsPct: 18,
  energySavedKwh: '4.200',
  estimatedRoiBrl: '8.450',
};

const fallbackProductivity = [
  { label: 'Talhão A', currentCycle: 68.0, previousCycle: 60.0 },
  { label: 'Talhão B', currentCycle: 74.0, previousCycle: 64.0 },
  { label: 'Talhão C', currentCycle: 56.0, previousCycle: 52.0 },
  { label: 'Talhão D', currentCycle: 78.0, previousCycle: 68.0 },
];

const exportableList = [
  { id: 'water_report', title: 'Consumo de Água', formatAndPeriod: 'PDF, CSV • Últimos 30 dias', fileType: 'pdf' },
  { id: 'events_report', title: 'Histórico de Eventos', formatAndPeriod: 'CSV • Todos os sensores', fileType: 'csv' },
  { id: 'energy_report', title: 'Eficiência Energética', formatAndPeriod: 'PDF • Relatório Detalhado', fileType: 'pdf' },
];

exports.getReportsOverview = async (req, res) => {
  try {
    let productivity = fallbackProductivity;

    if (db.isDbConnected()) {
      const prodRes = await db.query('SELECT plot_label, current_cycle_yield, previous_cycle_yield FROM productivity_metrics');
      if (prodRes.rows.length > 0) {
        productivity = prodRes.rows.map(r => ({
          label: r.plot_label,
          currentCycle: parseFloat(r.current_cycle_yield),
          previousCycle: parseFloat(r.previous_cycle_yield),
        }));
      }
    }

    return res.json({
      summary: fallbackMonthlySummary,
      productivity,
      compliance: {
        certificateName: 'Certificado Verde',
        status: 'ATIVO',
        waterReductionGoalPct: 85,
      },
      exportableReports: exportableList,
    });
  } catch (error) {
    console.error('Error fetching reports overview:', error);
    return res.json({
      summary: fallbackMonthlySummary,
      productivity: fallbackProductivity,
      compliance: {
        certificateName: 'Certificado Verde',
        status: 'ATIVO',
        waterReductionGoalPct: 85,
      },
      exportableReports: exportableList,
    });
  }
};

exports.downloadReport = (req, res) => {
  const { id } = req.params;
  const report = exportableList.find(r => r.id === id);
  if (!report) {
    return res.status(404).json({ error: 'Relatório não encontrado' });
  }

  // Generate simple CSV content for demonstration
  const csvContent = `Data,Setor,Metrica,Valor\n2026-10-14,Setor A,Consumo,105 m3\n2026-10-14,Setor B,Consumo,102 m3\n`;
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', `attachment; filename="${id}.csv"`);
  return res.send(csvContent);
};
