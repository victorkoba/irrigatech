const db = require('../config/db');

// Inicia vazio: alertas na Dashboard só entram quando algum setor monitorado
// apresentar consumo/valor muito alto de água, energia e/ou temperatura.
let fallbackAlerts = [];

exports.getFallbackAlerts = () => fallbackAlerts.filter(a => !a.is_resolved);

/**
 * Avalia um setor monitorado quanto aos limites de Água, Energia e Temperatura.
 * Grava/atualiza o alerta no banco de dados caso os valores estejam muito altos,
 * ou resolve automaticamente caso voltem ao normal.
 */
exports.evaluateSectorThresholds = async (sector) => {
  if (!sector || !sector.id) return null;

  const waterVal = parseFloat(sector.flow_rate ?? sector.flowRate ?? sector.water_consumption ?? sector.waterConsumption ?? 0);
  const energyVal = parseFloat(sector.energy_consumption ?? sector.energyConsumption ?? 0);
  const tempVal = parseFloat(sector.temperature ?? 0);

  const waterLimit = parseFloat(sector.water_alert_threshold ?? sector.waterAlertThreshold ?? 80.0);
  const energyLimit = parseFloat(sector.energy_alert_threshold ?? sector.energyAlertThreshold ?? 100.0);
  const tempLimit = parseFloat(sector.temperature_alert_threshold ?? sector.temperatureAlertThreshold ?? 35.0);

  const isWaterHigh = waterVal >= waterLimit;
  const isEnergyHigh = energyVal >= energyLimit;
  const isTempHigh = tempVal >= tempLimit;

  const alertId = `alert_threshold_${sector.id}`;
  const sectorName = sector.name || sector.id;

  // Condição: Consumo/valor muito alto de água, energia e/ou temperatura no setor monitorado
  if (isWaterHigh || isEnergyHigh || isTempHigh) {
    const exceededParts = [];
    if (isWaterHigh) exceededParts.push(`Água: ${waterVal.toFixed(1)} m³/h (limite ${waterLimit} m³/h)`);
    if (isEnergyHigh) exceededParts.push(`Energia: ${energyVal.toFixed(1)} kWh (limite ${energyLimit} kWh)`);
    if (isTempHigh) exceededParts.push(`Temperatura: ${tempVal.toFixed(1)}°C (limite ${tempLimit}°C)`);

    const allThreeHigh = isWaterHigh && isEnergyHigh && isTempHigh;
    const title = allThreeHigh
      ? `Alerta Crítico no ${sectorName}: Água, Energia e Temperatura elevadas`
      : `Consumo/Valor muito alto no ${sectorName}`;
    const description = `Monitoramento detectou índices acima do limite no ${sectorName}: ${exceededParts.join(' | ')}.`;
    const severity = (allThreeHigh || (isWaterHigh && isEnergyHigh) || tempVal >= 40) ? 'critical' : 'warning';
    const metricType = allThreeHigh ? 'combined' : (isWaterHigh ? 'water' : (isEnergyHigh ? 'energy' : 'temperature'));

    if (db.isDbConnected()) {
      const upsertRes = await db.query(
        `INSERT INTO alerts (id, sector_id, title, description, severity, metric_type, water_value, energy_value, temperature_value, is_resolved, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, FALSE, NOW())
         ON CONFLICT (id) DO UPDATE SET
           title = EXCLUDED.title,
           description = EXCLUDED.description,
           severity = EXCLUDED.severity,
           metric_type = EXCLUDED.metric_type,
           water_value = EXCLUDED.water_value,
           energy_value = EXCLUDED.energy_value,
           temperature_value = EXCLUDED.temperature_value,
           is_resolved = FALSE,
           created_at = NOW()
         RETURNING *`,
        [alertId, sector.id, title, description, severity, metricType, waterVal, energyVal, tempVal]
      );
      return formatAlertRow(upsertRes.rows[0]);
    }

    const existingIdx = fallbackAlerts.findIndex(a => a.id === alertId);
    const alertObj = {
      id: alertId,
      sector_id: sector.id,
      title,
      description,
      severity,
      metric_type: metricType,
      water_value: waterVal,
      energy_value: energyVal,
      temperature_value: tempVal,
      is_resolved: false,
      created_at: new Date().toISOString(),
    };
    if (existingIdx >= 0) {
      fallbackAlerts[existingIdx] = alertObj;
    } else {
      fallbackAlerts.unshift(alertObj);
    }
    return formatAlertRow(alertObj);
  } else {
    // Caso contrário, resolve qualquer alerta automático daquele setor para não aparecer na Dashboard
    if (db.isDbConnected()) {
      await db.query('UPDATE alerts SET is_resolved = TRUE WHERE id = $1 AND is_resolved = FALSE', [alertId]);
    } else {
      const existing = fallbackAlerts.find(a => a.id === alertId);
      if (existing) existing.is_resolved = true;
    }
    return null;
  }
};

exports.getAllAlerts = async (req, res) => {
  const includeResolved = req.query.all === 'true';
  try {
    if (db.isDbConnected()) {
      // Antes de listar, sincroniza a avaliação dos setores atuais do monitoramento
      const sectorsRes = await db.query('SELECT * FROM sectors');
      for (const sec of sectorsRes.rows) {
        await exports.evaluateSectorThresholds(sec);
      }

      const query = includeResolved
        ? 'SELECT * FROM alerts ORDER BY created_at DESC'
        : 'SELECT * FROM alerts WHERE is_resolved = false ORDER BY created_at DESC';
      const result = await db.query(query);
      return res.json(result.rows.map(formatAlertRow));
    }
    const filtered = includeResolved ? fallbackAlerts : fallbackAlerts.filter(a => !a.is_resolved);
    return res.json(filtered.map(formatAlertRow));
  } catch (error) {
    console.error('Error fetching alerts:', error);
    return res.status(500).json({ error: 'Erro ao consultar alertas do banco de dados' });
  }
};

exports.createAlert = async (req, res) => {
  const { title, description, severity = 'warning', sectorId, metricType = 'threshold', waterValue, energyValue, temperatureValue } = req.body;

  if (!title || !description) {
    return res.status(400).json({ error: 'Título e descrição são obrigatórios para registrar o alerta.' });
  }

  const validSeverities = ['critical', 'warning', 'info'];
  const finalSeverity = validSeverities.includes(severity) ? severity : 'warning';
  const id = `alert_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

  try {
    if (db.isDbConnected()) {
      const result = await db.query(
        `INSERT INTO alerts (id, sector_id, title, description, severity, metric_type, water_value, energy_value, temperature_value, is_resolved, created_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, FALSE, NOW()) RETURNING *`,
        [id, sectorId || null, title, description, finalSeverity, metricType, waterValue ?? null, energyValue ?? null, temperatureValue ?? null]
      );
      return res.status(201).json(formatAlertRow(result.rows[0]));
    }

    const newAlert = {
      id,
      sector_id: sectorId || null,
      title,
      description,
      severity: finalSeverity,
      metric_type: metricType,
      water_value: waterValue ?? null,
      energy_value: energyValue ?? null,
      temperature_value: temperatureValue ?? null,
      is_resolved: false,
      created_at: new Date().toISOString(),
    };
    fallbackAlerts.unshift(newAlert);
    return res.status(201).json(formatAlertRow(newAlert));
  } catch (error) {
    console.error('Error creating alert:', error);
    return res.status(500).json({ error: 'Erro ao gravar alerta no banco de dados' });
  }
};

exports.resolveAlert = async (req, res) => {
  const { id } = req.params;

  try {
    if (db.isDbConnected()) {
      const result = await db.query(
        'UPDATE alerts SET is_resolved = TRUE WHERE id = $1 RETURNING *',
        [id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Alerta não encontrado no banco de dados' });
      }
      return res.json({
        message: 'Alerta resolvido com sucesso',
        alert: formatAlertRow(result.rows[0]),
      });
    }

    const alert = fallbackAlerts.find(a => a.id === id);
    if (!alert) {
      return res.status(404).json({ error: 'Alerta não encontrado' });
    }
    alert.is_resolved = true;
    return res.json({
      message: 'Alerta resolvido com sucesso',
      alert: formatAlertRow(alert),
    });
  } catch (error) {
    console.error('Error resolving alert:', error);
    return res.status(500).json({ error: 'Erro ao resolver alerta no banco de dados' });
  }
};

exports.deleteAlert = async (req, res) => {
  const { id } = req.params;

  try {
    if (db.isDbConnected()) {
      const result = await db.query('DELETE FROM alerts WHERE id = $1 RETURNING *', [id]);
      if (result.rows.length === 0) {
        return res.status(404).json({ error: 'Alerta não encontrado para remoção' });
      }
      return res.json({ message: 'Alerta removido com sucesso', id });
    }

    const index = fallbackAlerts.findIndex(a => a.id === id);
    if (index === -1) {
      return res.status(404).json({ error: 'Alerta não encontrado para remoção' });
    }
    fallbackAlerts.splice(index, 1);
    return res.json({ message: 'Alerta removido com sucesso', id });
  } catch (error) {
    console.error('Error deleting alert:', error);
    return res.status(500).json({ error: 'Erro ao remover alerta do banco de dados' });
  }
};

function formatAlertRow(row) {
  return {
    id: row.id,
    sectorId: row.sector_id,
    title: row.title,
    description: row.description,
    severity: row.severity,
    metricType: row.metric_type || 'threshold',
    waterValue: row.water_value !== null && row.water_value !== undefined ? parseFloat(row.water_value) : null,
    energyValue: row.energy_value !== null && row.energy_value !== undefined ? parseFloat(row.energy_value) : null,
    temperatureValue: row.temperature_value !== null && row.temperature_value !== undefined ? parseFloat(row.temperature_value) : null,
    isResolved: Boolean(row.is_resolved),
    createdAt: row.created_at,
    timestamp: row.created_at,
  };
}

exports.formatAlertRow = formatAlertRow;
