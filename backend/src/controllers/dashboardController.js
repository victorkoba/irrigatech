const db = require('../config/db');

// In-memory fallback state
const mockDashboard = {
  isSystemActive: true,
  nextIrrigation: {
    time: '14:30',
    sectors: 'Setores B e D (Milho)',
    dailyProgressPct: 65,
  },
  kpis: {
    waterConsumption: { value: '1.2k', unit: 'm³/h', trend: '-5% vs ontem' },
    energyConsumption: { value: '450', unit: 'kWh', trend: '+2% vs ontem' },
    efficiency: { value: '94', unit: '%', trend: 'Excelente' },
  },
  criticalAlerts: [
    {
      id: 'alert_1',
      title: 'Umidade baixa no Setor A',
      description: 'Níveis abaixo de 15%. Irrigação de emergência recomendada.',
      severity: 'critical',
      timestamp: new Date().toISOString(),
    },
    {
      id: 'alert_2',
      title: 'Vazamento detectado no Setor C',
      description: 'Pressão anormal na linha principal detectada há 10 min.',
      severity: 'warning',
      timestamp: new Date().toISOString(),
    },
  ],
};

exports.getDashboardSummary = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const settingsRes = await db.query('SELECT * FROM automation_settings LIMIT 1');
      const alertsRes = await db.query("SELECT * FROM alerts WHERE is_resolved = false ORDER BY created_at DESC");

      const settings = settingsRes.rows[0] || {};
      return res.json({
        isSystemActive: settings.is_system_active ?? true,
        nextIrrigation: {
          time: settings.next_irrigation_time || '14:30',
          sectors: settings.next_irrigation_sectors || 'Setores B e D (Milho)',
          dailyProgressPct: parseFloat(settings.daily_progress_pct || 65),
        },
        kpis: mockDashboard.kpis,
        criticalAlerts: alertsRes.rows.map(a => ({
          id: a.id,
          title: a.title,
          description: a.description,
          severity: a.severity,
          timestamp: a.created_at,
        })),
      });
    }

    // Fallback
    return res.json(mockDashboard);
  } catch (error) {
    console.error('Error fetching dashboard summary:', error);
    return res.json(mockDashboard);
  }
};
