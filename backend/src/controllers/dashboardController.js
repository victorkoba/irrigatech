const db = require('../config/db');
const alertController = require('./alertController');
const irrigationController = require('./irrigationController');
const sectorController = require('./sectorController');
const monitoringController = require('./monitoringController');

const DEFAULT_METADATA = {
  summaryDescription:
    'Clientes corporativos no segmento agrícola enfrentam dificuldades em controlar o uso eficiente da água e energia, pois o manejo é feito com base em monitoramento manual. Isso ocasiona desperdício de água, custos crescentes de energia elétrica, baixa precisão na irrigação que compromete a produtividade e dificuldade em mensurar resultados com base em dados concretos.',
  expectedBenefits:
    'Monitoramento da umidade do solo e variáveis climáticas em tempo real; Acionamento inteligente e automático; Geração de relatórios automáticos de economia de água, energia e produtividade; Controle remoto via aplicativo mobile, dispensando deslocamentos até o campo; Garantia de conformidade ambiental, facilitando certificações e acesso a linhas de crédito rural sustentáveis.',
  detailedDescription:
    'Empresas agrícolas com sistemas de irrigação manuais enfrentam altos custos operacionais e desperdício de recursos naturais por falta de automação e monitoramento inteligente. Elas precisam de uma solução acessível e integrada que otimize o uso de água e energia, aumente a produtividade e garanta conformidade ambiental. Os equipamentos existentes atualmente precisam ser importados o que aumenta os recursos para investimento.',
  statusCardDescription:
    'Estado em que o controle de irrigação está definido pelo cliente.',
};

const DEFAULT_FEATURES = [
  {
    id: 'feat_status_geral',
    module: 'Dashboard',
    title: 'Status Geral do Sistema',
    description: 'Exibe se o sistema está Ativo ou Suspenso, representando o estado em que o controle de irrigação foi definido pelo cliente.',
  },
  {
    id: 'feat_alertas_condicionais',
    module: 'Dashboard',
    title: 'Alertas de Consumo e Temperatura',
    description: 'Exibe alertas na Dashboard exclusivamente quando algum setor monitorado apresentar valores muito altos de consumo de água, energia elétrica e/ou temperatura.',
  },
  {
    id: 'feat_proxima_irrigacao',
    module: 'Dashboard / Controle',
    title: 'Próxima Irrigação Agendada',
    description: 'Resgata do banco de dados o próximo horário e setores programados para irrigação, configurados na aba de Controle.',
  },
  {
    id: 'feat_cards_media_horaria',
    module: 'Dashboard / Monitoramento',
    title: 'Cards de Média Consolidada (1 em 1 hora)',
    description: 'Resgata do banco de dados as leituras geradas pelo monitoramento (script Python) a cada 1 hora, calcula a média do período e mantém os indicadores estáticos durante os 59 minutos seguintes.',
  },
];

// Snapshot em memória para fallback quando o banco estiver offline
let fallbackHourlySnapshot = null;

async function getOrCalculateHourlySnapshot(forceRefresh = false) {
  if (db.isDbConnected()) {
    if (!forceRefresh) {
      const existingRes = await db.query(
        'SELECT * FROM dashboard_hourly_snapshots ORDER BY calculated_at DESC LIMIT 1'
      );
      if (existingRes.rows.length > 0) {
        const snap = existingRes.rows[0];
        const now = new Date();
        const nextUpdate = new Date(snap.next_update_at);

        // Durante os 59 minutos após o resgate, retorna o valor estático salvo no banco
        if (now < nextUpdate) {
          const minutesRemaining = Math.max(1, Math.ceil((nextUpdate - now) / 60000));
          return formatSnapshot(snap, true, minutesRemaining);
        }
      }
    }

    // Passou 1 hora (ou primeiro cálculo): resgata leituras da última 1 hora no banco e tira a média
    let avgRes = await db.query(`
      SELECT
        COUNT(*) AS samples_count,
        AVG(water_consumption) AS avg_water,
        AVG(energy_consumption) AS avg_energy,
        AVG(temperature) AS avg_temp,
        AVG(moisture) AS avg_moisture,
        AVG(efficiency) AS avg_efficiency
      FROM sensor_readings
      WHERE recorded_at >= NOW() - INTERVAL '1 hour'
    `);

    let row = avgRes.rows[0];
    let samplesCount = parseInt(row.samples_count || '0', 10);

    if (samplesCount === 0) {
      // Se não houver leituras nos últimos 60 min, tira a média das últimas leituras registradas no banco
      avgRes = await db.query(`
        SELECT
          COUNT(*) AS samples_count,
          AVG(water_consumption) AS avg_water,
          AVG(energy_consumption) AS avg_energy,
          AVG(temperature) AS avg_temp,
          AVG(moisture) AS avg_moisture,
          AVG(efficiency) AS avg_efficiency
        FROM sensor_readings
      `);
      row = avgRes.rows[0];
      samplesCount = parseInt(row.samples_count || '1', 10);
    }

    const avgWater = parseFloat(row.avg_water ?? 46.5).toFixed(1);
    const avgEnergy = parseFloat(row.avg_energy ?? 43.0).toFixed(1);
    const avgTemp = parseFloat(row.avg_temp ?? 27.8).toFixed(1);
    const avgMoisture = parseFloat(row.avg_moisture ?? 45.5).toFixed(1);
    const avgEfficiency = parseFloat(row.avg_efficiency ?? 94.5).toFixed(1);

    const insertSnap = await db.query(
      `INSERT INTO dashboard_hourly_snapshots (
        avg_water_consumption,
        avg_energy_consumption,
        avg_temperature,
        avg_moisture,
        avg_efficiency,
        water_trend,
        energy_trend,
        efficiency_trend,
        samples_count,
        window_start,
        window_end,
        calculated_at,
        next_update_at
      ) VALUES (
        $1, $2, $3, $4, $5,
        'Média 1h (estático por 59 min)',
        'Média 1h (estático por 59 min)',
        'Média 1h (estático por 59 min)',
        $6,
        NOW() - INTERVAL '1 hour',
        NOW(),
        NOW(),
        NOW() + INTERVAL '1 hour'
      ) RETURNING *`,
      [avgWater, avgEnergy, avgTemp, avgMoisture, avgEfficiency, Math.max(1, samplesCount)]
    );

    return formatSnapshot(insertSnap.rows[0], false, 59);
  }

  // Fallback em memória (mesma regra de 1 hora estático por 59 min)
  const now = new Date();
  if (!forceRefresh && fallbackHourlySnapshot && now < new Date(fallbackHourlySnapshot.next_update_at)) {
    const minutesRemaining = Math.max(1, Math.ceil((new Date(fallbackHourlySnapshot.next_update_at) - now) / 60000));
    return formatSnapshot(fallbackHourlySnapshot, true, minutesRemaining);
  }

  const readings = monitoringController.getFallbackReadings();
  const count = readings.length || 1;
  const avgWater = readings.reduce((acc, r) => acc + (r.waterConsumption ?? 45.0), 0) / count;
  const avgEnergy = readings.reduce((acc, r) => acc + (r.energyConsumption ?? 42.0), 0) / count;
  const avgTemp = readings.reduce((acc, r) => acc + (r.temperature ?? 27.5), 0) / count;
  const avgMoisture = readings.reduce((acc, r) => acc + (r.moisture ?? 45.0), 0) / count;
  const avgEff = readings.reduce((acc, r) => acc + (r.efficiency ?? 94.0), 0) / count;

  fallbackHourlySnapshot = {
    avg_water_consumption: avgWater.toFixed(1),
    avg_energy_consumption: avgEnergy.toFixed(1),
    avg_temperature: avgTemp.toFixed(1),
    avg_moisture: avgMoisture.toFixed(1),
    avg_efficiency: avgEff.toFixed(1),
    water_trend: 'Média 1h (estático por 59 min)',
    energy_trend: 'Média 1h (estático por 59 min)',
    efficiency_trend: 'Média 1h (estático por 59 min)',
    samples_count: count,
    window_start: new Date(now.getTime() - 3600000).toISOString(),
    window_end: now.toISOString(),
    calculated_at: now.toISOString(),
    next_update_at: new Date(now.getTime() + 3600000).toISOString(),
  };

  return formatSnapshot(fallbackHourlySnapshot, false, 59);
}

function formatSnapshot(snap, isStaticCache, minutesRemaining) {
  const waterVal = parseFloat(snap.avg_water_consumption ?? 45.0);
  const energyVal = parseFloat(snap.avg_energy_consumption ?? 42.0);
  const tempVal = parseFloat(snap.avg_temperature ?? 27.5);
  const moistureVal = parseFloat(snap.avg_moisture ?? 45.0);
  const effVal = parseFloat(snap.avg_efficiency ?? 94.0);

  return {
    kpis: {
      waterConsumption: {
        value: waterVal.toFixed(1),
        unit: 'm³/h',
        trend: `Média 1h • estático (${minutesRemaining} min restantes)`,
      },
      energyConsumption: {
        value: energyVal.toFixed(1),
        unit: 'kWh',
        trend: `Média 1h • estático (${minutesRemaining} min restantes)`,
      },
      efficiency: {
        value: effVal.toFixed(0),
        unit: '%',
        trend: `Temp. média ${tempVal.toFixed(1)}°C • ciclo de 1h`,
      },
      temperature: {
        value: tempVal.toFixed(1),
        unit: '°C',
        trend: `Média 1h • estático (${minutesRemaining} min restantes)`,
      },
    },
    hourlySnapshot: {
      avgWaterConsumption: waterVal,
      avgEnergyConsumption: energyVal,
      avgTemperature: tempVal,
      avgMoisture: moistureVal,
      avgEfficiency: effVal,
      samplesCount: parseInt(snap.samples_count || 1, 10),
      calculatedAt: snap.calculated_at,
      nextUpdateAt: snap.next_update_at,
      minutesRemaining,
      isStaticCache,
      intervalMinutes: 60,
    },
  };
}

exports.getDashboardSummary = async (req, res) => {
  const forceRefreshHourly = req.query.forceRefreshHourly === 'true';

  try {
    const hourlyData = await getOrCalculateHourlySnapshot(forceRefreshHourly);

    if (db.isDbConnected()) {
      const settingsRes = await db.query('SELECT * FROM automation_settings LIMIT 1');
      const activeRes = await db.query("SELECT COUNT(*) FROM sectors WHERE status = 'irrigating'");
      const hasActive = parseInt(activeRes.rows[0].count, 10) > 0;

      // Avalia todos os setores monitorados para garantir que só existam alertas
      // se algum setor estiver com água, energia e/ou temperatura muito altos
      const allSectorsRes = await db.query('SELECT * FROM sectors');
      for (const sec of allSectorsRes.rows) {
        await alertController.evaluateSectorThresholds(sec);
      }

      const alertsRes = await db.query(
        'SELECT * FROM alerts WHERE is_resolved = false ORDER BY created_at DESC'
      );

      let metadata = DEFAULT_METADATA;
      try {
        const metaRes = await db.query('SELECT * FROM system_metadata LIMIT 1');
        if (metaRes.rows.length > 0) {
          const m = metaRes.rows[0];
          metadata = {
            summaryDescription: m.summary_description,
            expectedBenefits: m.expected_benefits,
            detailedDescription: m.detailed_description,
            statusCardDescription: m.status_card_description,
          };
        }
      } catch (_) {}

      let features = DEFAULT_FEATURES;
      try {
        const featRes = await db.query('SELECT * FROM system_features WHERE is_active = true ORDER BY id ASC');
        if (featRes.rows.length > 0) {
          features = featRes.rows.map(f => ({
            id: f.id,
            module: f.module,
            title: f.title,
            description: f.description,
          }));
        }
      } catch (_) {}

      const settings = settingsRes.rows[0] || {};
      const isSystemActive = Boolean(settings.is_system_active || hasActive);

      return res.json({
        isSystemActive,
        statusCardDescription: metadata.statusCardDescription,
        systemMetadata: metadata,
        systemFeatures: features,
        nextIrrigation: {
          time: settings.next_irrigation_time || '14:30',
          sectors: settings.next_irrigation_sectors || 'Setores B e D (Milho)',
          dailyProgressPct: parseFloat(settings.daily_progress_pct || 65),
        },
        kpis: hourlyData.kpis,
        hourlySnapshot: hourlyData.hourlySnapshot,
        criticalAlerts: alertsRes.rows.map(alertController.formatAlertRow),
      });
    }

    // Fallback
    const fallbackSecs = sectorController.getFallbackSectors();
    for (const sec of fallbackSecs) {
      await alertController.evaluateSectorThresholds(sec);
    }

    const isSystemActive =
      irrigationController.getFallbackIsSystemActive() || sectorController.hasActiveFallbackSectors();

    return res.json({
      isSystemActive,
      statusCardDescription: DEFAULT_METADATA.statusCardDescription,
      systemMetadata: DEFAULT_METADATA,
      systemFeatures: DEFAULT_FEATURES,
      nextIrrigation: {
        time: '14:30',
        sectors: 'Setores B e D (Milho)',
        dailyProgressPct: 65,
      },
      kpis: hourlyData.kpis,
      hourlySnapshot: hourlyData.hourlySnapshot,
      criticalAlerts: alertController.getFallbackAlerts().map(alertController.formatAlertRow),
    });
  } catch (error) {
    console.error('Error fetching dashboard summary:', error);
    return res.status(500).json({ error: 'Erro ao carregar dados da dashboard' });
  }
};
