const db = require('../config/db');
const alertController = require('./alertController');

let fallbackSectors = [
  {
    id: 'setor_a',
    name: 'Setor A',
    region: 'Norte',
    status: 'irrigating',
    isEnabled: true,
    idealMoisture: 60.0,
    minMoistureTrigger: 35.0,
    maxMoistureCutoff: 75.0,
    flowRate: 45.0,
    energyConsumption: 42.0,
    moisture: 45.0,
    temperature: 28.0,
    lastActivatedAt: new Date().toISOString(),
    activationReason: 'Acionamento Automático: Umidade abaixo da ideal (45% < 60%)',
  },
  {
    id: 'setor_b',
    name: 'Setor B',
    region: 'Leste',
    status: 'idle',
    isEnabled: true,
    idealMoisture: 60.0,
    minMoistureTrigger: 35.0,
    maxMoistureCutoff: 75.0,
    flowRate: 0.0,
    energyConsumption: 0.0,
    moisture: 60.0,
    temperature: 26.5,
  },
  {
    id: 'setor_c',
    name: 'Setor C',
    region: 'Sul',
    status: 'error',
    isEnabled: true,
    idealMoisture: 60.0,
    minMoistureTrigger: 35.0,
    maxMoistureCutoff: 75.0,
    flowRate: 0.0,
    energyConsumption: 0.0,
    moisture: 18.0,
    temperature: 31.0,
    alertMessage: 'Vazamento Detectado',
  },
  {
    id: 'setor_d',
    name: 'Setor D',
    region: 'Oeste',
    status: 'idle',
    isEnabled: true,
    idealMoisture: 50.0,
    minMoistureTrigger: 30.0,
    maxMoistureCutoff: 75.0,
    flowRate: 0.0,
    energyConsumption: 0.0,
    moisture: 52.0,
    temperature: 27.0,
  },
  {
    id: 'setor_e',
    name: 'Setor E',
    region: 'Central',
    status: 'idle',
    isEnabled: true,
    idealMoisture: 55.0,
    minMoistureTrigger: 30.0,
    maxMoistureCutoff: 75.0,
    flowRate: 0.0,
    energyConsumption: 0.0,
    moisture: 58.0,
    temperature: 26.0,
  },
];

function formatSectorRow(s) {
  return {
    id: s.id,
    name: s.name,
    region: s.region,
    status: s.status,
    isEnabled: s.is_enabled !== undefined ? Boolean(s.is_enabled) : true,
    idealMoisture: parseFloat(s.ideal_moisture ?? 60.0),
    minMoistureTrigger: parseFloat(s.min_moisture_trigger ?? 35.0),
    maxMoistureCutoff: parseFloat(s.max_moisture_cutoff ?? 75.0),
    flowRate: parseFloat(s.flow_rate ?? 0.0),
    energyConsumption: parseFloat(s.energy_consumption ?? 0.0),
    moisture: parseFloat(s.moisture ?? 50.0),
    temperature: parseFloat(s.temperature ?? 25.0),
    alertMessage: s.alert_message || null,
    lastActivatedAt: s.last_activated_at || null,
    activationReason: s.activation_reason || null,
  };
}

/**
 * Avalia automaticamente se a irrigação do setor deve ser acionada ou desligada
 * com base na umidade ideal, nos parâmetros de automação do setor e na temperatura.
 * Se acionada, grava o evento em `irrigation_events` para exibição nos Relatórios.
 */
async function evaluateSectorAutomationDb(sectorRow) {
  if (!sectorRow || sectorRow.status === 'error') return sectorRow;

  const isEnabled = sectorRow.is_enabled !== undefined ? Boolean(sectorRow.is_enabled) : true;
  const moisture = parseFloat(sectorRow.moisture ?? 50.0);
  const temperature = parseFloat(sectorRow.temperature ?? 25.0);
  const idealMoisture = parseFloat(sectorRow.ideal_moisture ?? 60.0);
  const minTrigger = parseFloat(sectorRow.min_moisture_trigger ?? 35.0);
  const maxCutoff = parseFloat(sectorRow.max_moisture_cutoff ?? 75.0);

  // Se o setor estiver desativado na chave Liga/Desliga, não aciona irrigação
  if (!isEnabled) {
    if (sectorRow.status === 'irrigating') {
      const upd = await db.query(
        `UPDATE sectors
         SET status = 'idle', flow_rate = 0, activation_reason = NULL, updated_at = NOW()
         WHERE id = $1 RETURNING *`,
        [sectorRow.id]
      );
      return upd.rows[0] || sectorRow;
    }
    return sectorRow;
  }

  const isMoistureLow = moisture < idealMoisture || moisture <= minTrigger;
  const isTempHigh = temperature >= 32.0;

  if (isMoistureLow || isTempHigh) {
    let reason = '';
    if (isMoistureLow && isTempHigh) {
      reason = `Automático: Umidade (${moisture.toFixed(0)}% < ideal ${idealMoisture.toFixed(0)}%) e Temp. alta (${temperature.toFixed(1)}°C)`;
    } else if (isMoistureLow) {
      reason = `Automático: Umidade abaixo da ideal (${moisture.toFixed(0)}% < ${idealMoisture.toFixed(0)}%)`;
    } else {
      reason = `Automático: Temperatura elevada (${temperature.toFixed(1)}°C)`;
    }

    const wasIrrigating = sectorRow.status === 'irrigating';
    const newFlow = parseFloat(sectorRow.flow_rate) > 0 ? parseFloat(sectorRow.flow_rate) : 45.0;

    const upd = await db.query(
      `UPDATE sectors
       SET status = 'irrigating',
           flow_rate = $1,
           last_activated_at = CASE WHEN status != 'irrigating' OR last_activated_at IS NULL THEN NOW() ELSE last_activated_at END,
           activation_reason = $2,
           updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [newFlow, reason, sectorRow.id]
    );

    if (!wasIrrigating) {
      await db.query('UPDATE automation_settings SET is_system_active = true, updated_at = NOW()');
      await db.query(
        `INSERT INTO irrigation_events (sector_id, start_time, triggered_by)
         VALUES ($1, NOW(), $2)`,
        [sectorRow.id, reason]
      );
    }
    return upd.rows[0] || sectorRow;
  } else if (moisture >= idealMoisture && moisture >= maxCutoff && !isTempHigh && sectorRow.status === 'irrigating') {
    const upd = await db.query(
      `UPDATE sectors
       SET status = 'idle', flow_rate = 0, activation_reason = NULL, updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [sectorRow.id]
    );
    return upd.rows[0] || sectorRow;
  }

  return sectorRow;
}

exports.evaluateSectorAutomationDb = evaluateSectorAutomationDb;
exports.getFallbackSectors = () => fallbackSectors;

exports.stopAllFallbackSectors = () => {
  fallbackSectors.forEach(s => {
    if (s.status === 'irrigating') {
      s.status = 'idle';
      s.flowRate = 0.0;
    }
  });
};

exports.getActiveFallbackSectors = () => {
  return fallbackSectors
    .filter(s => s.status === 'irrigating')
    .map(s => ({ id: s.id, flow_rate: s.flowRate || 40.0, flowRate: s.flowRate || 40.0 }));
};

exports.hasActiveFallbackSectors = () => {
  return fallbackSectors.some(s => s.status === 'irrigating');
};

exports.restoreFallbackSectors = (sectorsToRestore) => {
  sectorsToRestore.forEach(item => {
    const s = fallbackSectors.find(sec => sec.id === (item.id || item));
    if (s && s.status !== 'error') {
      s.status = 'irrigating';
      s.flowRate = item.flowRate || item.flow_rate || 40.0;
    }
  });
};

exports.getAllSectors = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query('SELECT * FROM sectors ORDER BY name ASC');
      return res.json(result.rows.map(formatSectorRow));
    }
    return res.json(fallbackSectors);
  } catch (error) {
    console.error('Error fetching sectors:', error);
    return res.json(fallbackSectors);
  }
};

exports.createSector = async (req, res) => {
  const {
    name,
    region,
    moisture,
    idealMoisture,
    minMoistureTrigger = 35.0,
    maxMoistureCutoff = 75.0,
    isEnabled = true,
  } = req.body;

  if (!name || !name.trim() || !region || !region.trim()) {
    return res.status(400).json({ error: 'Nome e região do setor são obrigatórios.' });
  }

  const cleanName = name.trim();
  const cleanRegion = region.trim();
  const ideal = idealMoisture !== undefined
    ? parseFloat(idealMoisture) || 60.0
    : (moisture !== undefined ? parseFloat(moisture) || 60.0 : 60.0);
  const minTrig = parseFloat(minMoistureTrigger) || 35.0;
  const maxCut = parseFloat(maxMoistureCutoff) || 75.0;
  const moist = moisture !== undefined ? parseFloat(moisture) : ideal;
  // Temperatura inicial padrão (será atualizada pelo script de monitoramento e exibida na tela de Monitoramento)
  const temp = 25.0;
  const enabledBool = isEnabled !== undefined ? Boolean(isEnabled) : true;

  const baseSlug = cleanName
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
  const id = `setor_${baseSlug || Date.now()}_${Date.now().toString().slice(-4)}`;

  try {
    if (db.isDbConnected()) {
      const insertRes = await db.query(
        `INSERT INTO sectors (
           id, name, region, status, is_enabled, ideal_moisture,
           min_moisture_trigger, max_moisture_cutoff, flow_rate, moisture, temperature
         )
         VALUES ($1, $2, $3, 'idle', $4, $5, $6, $7, 0.0, $8, $9)
         RETURNING *`,
        [id, cleanName, cleanRegion, enabledBool, ideal, minTrig, maxCut, moist, temp]
      );
      let row = insertRes.rows[0];
      // Se moisture for explicitamente menor que idealMoisture, avalia se precisa ativar
      if (moisture !== undefined && moist < ideal) {
        row = await evaluateSectorAutomationDb(row);
      }
      return res.status(201).json(formatSectorRow(row));
    }

    const newSector = {
      id,
      name: cleanName,
      region: cleanRegion,
      status: 'idle',
      isEnabled: enabledBool,
      idealMoisture: ideal,
      minMoistureTrigger: minTrig,
      maxMoistureCutoff: maxCut,
      flowRate: 0.0,
      moisture: moist,
      temperature: temp,
    };
    fallbackSectors.push(newSector);
    return res.status(201).json(newSector);
  } catch (error) {
    console.error('Error creating sector:', error);
    return res.status(500).json({ error: 'Erro ao cadastrar novo setor' });
  }
};

exports.updateSector = async (req, res) => {
  const { id } = req.params;
  const {
    name,
    region,
    idealMoisture,
    minMoistureTrigger,
    maxMoistureCutoff,
    isEnabled,
  } = req.body;

  if (!name || !name.trim() || !region || !region.trim()) {
    return res.status(400).json({ error: 'Nome e região do setor são obrigatórios.' });
  }

  try {
    if (db.isDbConnected()) {
      const existingRes = await db.query('SELECT * FROM sectors WHERE id = $1', [id]);
      if (existingRes.rows.length === 0) {
        return res.status(404).json({ error: 'Setor não encontrado' });
      }
      const curr = existingRes.rows[0];
      const newName = name.trim();
      const newRegion = region.trim();
      const newIdeal = idealMoisture !== undefined ? parseFloat(idealMoisture) : parseFloat(curr.ideal_moisture ?? 60.0);
      const newMin = minMoistureTrigger !== undefined ? parseFloat(minMoistureTrigger) : parseFloat(curr.min_moisture_trigger ?? 35.0);
      const newMax = maxMoistureCutoff !== undefined ? parseFloat(maxMoistureCutoff) : parseFloat(curr.max_moisture_cutoff ?? 75.0);
      const newEnabled = isEnabled !== undefined ? Boolean(isEnabled) : Boolean(curr.is_enabled ?? true);

      const updRes = await db.query(
        `UPDATE sectors
         SET name = $1,
             region = $2,
             ideal_moisture = $3,
             min_moisture_trigger = $4,
             max_moisture_cutoff = $5,
             is_enabled = $6,
             updated_at = NOW()
         WHERE id = $7
         RETURNING *`,
        [newName, newRegion, newIdeal, newMin, newMax, newEnabled, id]
      );

      let updatedRow = updRes.rows[0];
      // Atualiza também o nome na tabela weekly_consumption se mudou
      if (curr.name !== newName) {
        await db.query('UPDATE weekly_consumption SET sector_name = $1 WHERE sector_name = $2', [newName, curr.name]);
      }

      updatedRow = await evaluateSectorAutomationDb(updatedRow);
      return res.json(formatSectorRow(updatedRow));
    }

    const sector = fallbackSectors.find(s => s.id === id);
    if (!sector) return res.status(404).json({ error: 'Setor não encontrado' });
    sector.name = name.trim();
    sector.region = region.trim();
    if (idealMoisture !== undefined) sector.idealMoisture = parseFloat(idealMoisture);
    if (minMoistureTrigger !== undefined) sector.minMoistureTrigger = parseFloat(minMoistureTrigger);
    if (maxMoistureCutoff !== undefined) sector.maxMoistureCutoff = parseFloat(maxMoistureCutoff);
    if (isEnabled !== undefined) sector.isEnabled = Boolean(isEnabled);
    return res.json(sector);
  } catch (error) {
    console.error('Error updating sector:', error);
    return res.status(500).json({ error: 'Erro ao atualizar dados do setor' });
  }
};

exports.setSectorEnabled = async (req, res) => {
  const { id } = req.params;
  const { isEnabled } = req.body;

  try {
    if (db.isDbConnected()) {
      const sectorRes = await db.query('SELECT * FROM sectors WHERE id = $1', [id]);
      if (sectorRes.rows.length === 0) {
        return res.status(404).json({ error: 'Setor não encontrado' });
      }
      const curr = sectorRes.rows[0];
      const nextEnabled = isEnabled !== undefined ? Boolean(isEnabled) : !Boolean(curr.is_enabled);

      const updRes = await db.query(
        'UPDATE sectors SET is_enabled = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
        [nextEnabled, id]
      );
      const evaluated = await evaluateSectorAutomationDb(updRes.rows[0]);
      return res.json(formatSectorRow(evaluated));
    }

    const sector = fallbackSectors.find(s => s.id === id);
    if (!sector) return res.status(404).json({ error: 'Setor não encontrado' });
    sector.isEnabled = isEnabled !== undefined ? Boolean(isEnabled) : !sector.isEnabled;
    if (!sector.isEnabled && sector.status === 'irrigating') {
      sector.status = 'idle';
      sector.flowRate = 0.0;
    }
    return res.json(sector);
  } catch (error) {
    console.error('Error toggling sector enabled:', error);
    return res.status(500).json({ error: 'Erro ao alterar estado ativo/desativado do setor' });
  }
};

exports.toggleSector = async (req, res) => {
  const { id } = req.params;
  try {
    if (db.isDbConnected()) {
      const sectorRes = await db.query('SELECT * FROM sectors WHERE id = $1', [id]);
      if (sectorRes.rows.length === 0) {
        return res.status(404).json({ error: 'Setor não encontrado' });
      }
      const sector = sectorRes.rows[0];
      if (sector.status === 'error') {
        return res.status(400).json({ error: 'Setor em estado de erro não pode ser acionado' });
      }

      const isTurningOn = sector.status !== 'irrigating';
      const newStatus = isTurningOn ? 'irrigating' : 'idle';
      const newFlow = isTurningOn ? 40.0 : 0.0;

      await db.query(
        'UPDATE sectors SET status = $1, flow_rate = $2, is_enabled = true, updated_at = NOW() WHERE id = $3',
        [newStatus, newFlow, id]
      );

      // Record event and reactivate system
      if (isTurningOn) {
        await db.query('UPDATE automation_settings SET is_system_active = true, updated_at = NOW()');
        await db.query(
          'INSERT INTO irrigation_events (sector_id, start_time, triggered_by) VALUES ($1, NOW(), $2)',
          [id, 'Acionamento Automático / Controle']
        );
      }

      return res.json({ id, status: newStatus, flowRate: newFlow });
    }

    // Fallback
    const sector = fallbackSectors.find(s => s.id === id);
    if (!sector) return res.status(404).json({ error: 'Setor não encontrado' });
    if (sector.status === 'error') return res.status(400).json({ error: 'Setor em erro' });

    sector.status = sector.status === 'irrigating' ? 'idle' : 'irrigating';
    sector.flowRate = sector.status === 'irrigating' ? 40.0 : 0.0;
    if (sector.status === 'irrigating') {
      try { require('./irrigationController').resumeFallback(); } catch (_) {}
    }
    return res.json(sector);
  } catch (error) {
    console.error('Error toggling sector:', error);
    return res.status(500).json({ error: 'Falha ao alterar estado do setor' });
  }
};

exports.setFlowRate = async (req, res) => {
  const { id } = req.params;
  const { flowRate } = req.body;
  const rate = parseFloat(flowRate);

  try {
    if (db.isDbConnected()) {
      const upd = await db.query('UPDATE sectors SET flow_rate = $1, updated_at = NOW() WHERE id = $2 RETURNING *', [rate, id]);
      if (upd.rows.length > 0) {
        await alertController.evaluateSectorThresholds(upd.rows[0]);
      }
      return res.json({ id, flowRate: rate });
    }

    const sector = fallbackSectors.find(s => s.id === id);
    if (!sector) return res.status(404).json({ error: 'Setor não encontrado' });
    sector.flowRate = rate;
    await alertController.evaluateSectorThresholds(sector);
    return res.json(sector);
  } catch (error) {
    console.error('Error setting flow rate:', error);
    return res.status(500).json({ error: 'Falha ao alterar vazão' });
  }
};

exports.deleteSector = async (req, res) => {
  const { id } = req.params;
  try {
    if (db.isDbConnected()) {
      const delRes = await db.query('DELETE FROM sectors WHERE id = $1 RETURNING *', [id]);
      if (delRes.rows.length === 0) {
        return res.status(404).json({ error: 'Setor não encontrado para exclusão' });
      }
      const deletedSector = delRes.rows[0];
      await db.query('DELETE FROM weekly_consumption WHERE sector_name = $1', [deletedSector.name]);
      await db.query('DELETE FROM alerts WHERE sector_id = $1', [id]);
      return res.json({ message: 'Setor excluído com sucesso', id });
    }

    const idx = fallbackSectors.findIndex(s => s.id === id);
    if (idx === -1) {
      return res.status(404).json({ error: 'Setor não encontrado para exclusão' });
    }
    fallbackSectors.splice(idx, 1);
    return res.json({ message: 'Setor excluído com sucesso', id });
  } catch (error) {
    console.error('Error deleting sector:', error);
    return res.status(500).json({ error: 'Erro ao excluir setor' });
  }
};
