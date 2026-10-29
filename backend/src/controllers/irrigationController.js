const db = require('../config/db');
const sectorController = require('./sectorController');

let savedActiveSectors = [];

let fallbackSettings = {
  isSystemActive: true,
  operationMode: 'Automático',
  minMoistureTrigger: 30.0,
  maxMoistureCutoff: 75.0,
  nextIrrigationTime: '14:30',
  nextIrrigationSectors: 'Setor B, Setor D',
  dailyProgressPct: 65.0,
};

let fallbackSchedules = [
  {
    id: 'sched_default_1',
    time: '14:30',
    sectorIds: ['setor_b', 'setor_d'],
    sectorsLabel: 'Setor B, Setor D',
    isActive: true,
  },
  {
    id: 'sched_default_2',
    time: '06:00',
    sectorIds: ['ALL'],
    sectorsLabel: 'Todos os Setores',
    isActive: true,
  },
];

function formatScheduleRow(row) {
  let parsedIds = ['ALL'];
  try {
    parsedIds = JSON.parse(row.sector_ids || '["ALL"]');
    if (!Array.isArray(parsedIds)) parsedIds = [String(row.sector_ids)];
  } catch (_) {
    parsedIds = row.sector_ids ? String(row.sector_ids).split(',').map(s => s.trim()) : ['ALL'];
  }
  return {
    id: row.id,
    time: row.scheduled_time,
    sectorIds: parsedIds,
    sectorsLabel: row.sectors_label,
    isActive: Boolean(row.is_active),
    createdAt: row.created_at,
  };
}

async function syncNextActiveScheduleToSettings() {
  if (!db.isDbConnected()) return;
  try {
    const activeRes = await db.query(
      'SELECT * FROM irrigation_schedules WHERE is_active = true ORDER BY scheduled_time ASC LIMIT 1'
    );
    if (activeRes.rows.length > 0) {
      const next = activeRes.rows[0];
      await db.query(
        'UPDATE automation_settings SET next_irrigation_time = $1, next_irrigation_sectors = $2, updated_at = NOW()',
        [next.scheduled_time, next.sectors_label]
      );
    } else {
      await db.query(
        "UPDATE automation_settings SET next_irrigation_time = '--:--', next_irrigation_sectors = 'Nenhum agendamento ativo', updated_at = NOW()"
      );
    }
  } catch (err) {
    console.error('Error syncing next active schedule:', err);
  }
}

exports.resumeFallback = () => {
  fallbackSettings.isSystemActive = true;
};

exports.getFallbackIsSystemActive = () => {
  return fallbackSettings.isSystemActive;
};

exports.getSettings = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query('SELECT * FROM automation_settings LIMIT 1');
      if (result.rows.length > 0) {
        const s = result.rows[0];
        const activeRes = await db.query("SELECT COUNT(*) FROM sectors WHERE status = 'irrigating'");
        const hasActive = parseInt(activeRes.rows[0].count, 10) > 0;
        return res.json({
          isSystemActive: Boolean(s.is_system_active || hasActive),
          operationMode: s.operation_mode,
          minMoistureTrigger: parseFloat(s.min_moisture_trigger),
          maxMoistureCutoff: parseFloat(s.max_moisture_cutoff),
        });
      }
    }
    const isSystemActive = fallbackSettings.isSystemActive || sectorController.hasActiveFallbackSectors();
    return res.json({
      ...fallbackSettings,
      isSystemActive,
    });
  } catch (error) {
    console.error('Error fetching settings:', error);
    return res.json(fallbackSettings);
  }
};

exports.emergencyStop = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const activeRes = await db.query("SELECT id, flow_rate FROM sectors WHERE status = 'irrigating'");
      savedActiveSectors = activeRes.rows.map(r => ({
        id: r.id,
        flow_rate: parseFloat(r.flow_rate) || 40.0,
      }));

      await db.query('UPDATE automation_settings SET is_system_active = false, updated_at = NOW()');
      await db.query("UPDATE sectors SET status = 'idle', flow_rate = 0 WHERE status = 'irrigating'");
      return res.json({
        message: 'Parada de emergência executada.',
        isSystemActive: false,
        savedSectors: savedActiveSectors,
      });
    }

    savedActiveSectors = sectorController.getActiveFallbackSectors();
    fallbackSettings.isSystemActive = false;
    sectorController.stopAllFallbackSectors();
    return res.json({
      message: 'Parada de emergência executada.',
      isSystemActive: false,
      savedSectors: savedActiveSectors,
    });
  } catch (error) {
    console.error('Error executing emergency stop:', error);
    return res.status(500).json({ error: 'Erro ao executar parada de emergência' });
  }
};

exports.resumeSystem = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      await db.query('UPDATE automation_settings SET is_system_active = true, updated_at = NOW()');

      const toRestore = savedActiveSectors.length > 0
        ? savedActiveSectors
        : [{ id: 'setor_a', flow_rate: 45.0 }];

      for (const item of toRestore) {
        await db.query(
          "UPDATE sectors SET status = 'irrigating', flow_rate = $1, updated_at = NOW() WHERE id = $2 AND status != 'error'",
          [item.flow_rate || 40.0, item.id]
        );
      }

      const restoredList = [...toRestore];
      savedActiveSectors = [];

      return res.json({
        message: 'Sistema reativado.',
        isSystemActive: true,
        restoredSectors: restoredList,
      });
    }

    fallbackSettings.isSystemActive = true;
    const toRestore = savedActiveSectors.length > 0
      ? savedActiveSectors
      : [{ id: 'setor_a', flowRate: 45.0, flow_rate: 45.0 }];

    sectorController.restoreFallbackSectors(toRestore);
    const restoredList = [...toRestore];
    savedActiveSectors = [];

    return res.json({
      message: 'Sistema reativado.',
      isSystemActive: true,
      restoredSectors: restoredList,
    });
  } catch (error) {
    console.error('Error resuming system:', error);
    return res.status(500).json({ error: 'Erro ao reativar sistema' });
  }
};

exports.setMode = async (req, res) => {
  const { mode } = req.body;
  if (!['Automático', 'Manual'].includes(mode)) {
    return res.status(400).json({ error: 'Modo inválido. Use "Automático" ou "Manual".' });
  }

  try {
    if (db.isDbConnected()) {
      await db.query('UPDATE automation_settings SET operation_mode = $1, updated_at = NOW()', [mode]);
      return res.json({ operationMode: mode });
    }
    fallbackSettings.operationMode = mode;
    return res.json({ operationMode: mode });
  } catch (error) {
    console.error('Error setting mode:', error);
    return res.status(500).json({ error: 'Erro ao alterar modo' });
  }
};

exports.updateParameters = async (req, res) => {
  const { minMoisture, maxMoisture } = req.body;
  const min = parseFloat(minMoisture);
  const max = parseFloat(maxMoisture);

  try {
    if (db.isDbConnected()) {
      await db.query(
        'UPDATE automation_settings SET min_moisture_trigger = $1, max_moisture_cutoff = $2, updated_at = NOW()',
        [min, max]
      );
      return res.json({ minMoistureTrigger: min, maxMoistureCutoff: max });
    }
    fallbackSettings.minMoistureTrigger = min;
    fallbackSettings.maxMoistureCutoff = max;
    return res.json({ minMoistureTrigger: min, maxMoistureCutoff: max });
  } catch (error) {
    console.error('Error updating parameters:', error);
    return res.status(500).json({ error: 'Erro ao atualizar parâmetros' });
  }
};

exports.getSchedule = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query('SELECT next_irrigation_time, next_irrigation_sectors, daily_progress_pct FROM automation_settings LIMIT 1');
      if (result.rows.length > 0) {
        const s = result.rows[0];
        return res.json({
          time: s.next_irrigation_time || '14:30',
          sectors: s.next_irrigation_sectors || 'Setor B, Setor D',
          dailyProgressPct: parseFloat(s.daily_progress_pct || 65.0),
        });
      }
    }
    return res.json({
      time: fallbackSettings.nextIrrigationTime,
      sectors: fallbackSettings.nextIrrigationSectors,
      dailyProgressPct: fallbackSettings.dailyProgressPct,
    });
  } catch (error) {
    console.error('Error fetching schedule:', error);
    return res.status(500).json({ error: 'Erro ao consultar agendamento de irrigação' });
  }
};

exports.updateSchedule = async (req, res) => {
  const { time, sectors, dailyProgressPct = 65.0 } = req.body;

  if (!time || !sectors) {
    return res.status(400).json({ error: 'Horário e setores são obrigatórios para agendar a irrigação.' });
  }

  const progress = parseFloat(dailyProgressPct) || 65.0;

  try {
    if (db.isDbConnected()) {
      await db.query(
        'UPDATE automation_settings SET next_irrigation_time = $1, next_irrigation_sectors = $2, daily_progress_pct = $3, updated_at = NOW()',
        [time, sectors, progress]
      );
      return res.json({
        message: 'Agendamento de irrigação atualizado com sucesso',
        schedule: {
          time,
          sectors,
          dailyProgressPct: progress,
        },
      });
    }

    fallbackSettings.nextIrrigationTime = time;
    fallbackSettings.nextIrrigationSectors = sectors;
    fallbackSettings.dailyProgressPct = progress;

    return res.json({
      message: 'Agendamento de irrigação atualizado com sucesso',
      schedule: {
        time,
        sectors,
        dailyProgressPct: progress,
      },
    });
  } catch (error) {
    console.error('Error updating schedule:', error);
    return res.status(500).json({ error: 'Erro ao atualizar agendamento de irrigação no banco de dados' });
  }
};

// --- CRUD de Múltiplos Agendamentos ---

exports.getSchedules = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query('SELECT * FROM irrigation_schedules ORDER BY scheduled_time ASC');
      return res.json(result.rows.map(formatScheduleRow));
    }
    return res.json(fallbackSchedules);
  } catch (error) {
    console.error('Error fetching schedules:', error);
    return res.json(fallbackSchedules);
  }
};

exports.createSchedule = async (req, res) => {
  const { time, sectorIds = ['ALL'], sectorsLabel = 'Todos os Setores', isActive = true } = req.body;

  if (!time || !String(time).trim()) {
    return res.status(400).json({ error: 'O horário do agendamento é obrigatório.' });
  }

  const id = `sched_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
  const cleanTime = String(time).trim();
  const idsArray = Array.isArray(sectorIds) && sectorIds.length > 0 ? sectorIds : ['ALL'];
  const cleanLabel = String(sectorsLabel || 'Todos os Setores').trim();
  const activeBool = isActive !== undefined ? Boolean(isActive) : true;

  try {
    if (db.isDbConnected()) {
      const insertRes = await db.query(
        `INSERT INTO irrigation_schedules (id, scheduled_time, sector_ids, sectors_label, is_active)
         VALUES ($1, $2, $3, $4, $5)
         RETURNING *`,
        [id, cleanTime, JSON.stringify(idsArray), cleanLabel, activeBool]
      );
      await syncNextActiveScheduleToSettings();
      return res.status(201).json(formatScheduleRow(insertRes.rows[0]));
    }

    const newItem = {
      id,
      time: cleanTime,
      sectorIds: idsArray,
      sectorsLabel: cleanLabel,
      isActive: activeBool,
    };
    fallbackSchedules.push(newItem);
    return res.status(201).json(newItem);
  } catch (error) {
    console.error('Error creating schedule:', error);
    return res.status(500).json({ error: 'Erro ao criar agendamento de irrigação' });
  }
};

exports.updateScheduleItem = async (req, res) => {
  const { id } = req.params;
  const { time, sectorIds, sectorsLabel, isActive } = req.body;

  if (!time || !String(time).trim()) {
    return res.status(400).json({ error: 'O horário do agendamento é obrigatório.' });
  }

  try {
    if (db.isDbConnected()) {
      const existingRes = await db.query('SELECT * FROM irrigation_schedules WHERE id = $1', [id]);
      if (existingRes.rows.length === 0) {
        return res.status(404).json({ error: 'Agendamento não encontrado' });
      }
      const curr = existingRes.rows[0];
      const nextTime = String(time).trim();
      const nextIds = Array.isArray(sectorIds) && sectorIds.length > 0
        ? JSON.stringify(sectorIds)
        : curr.sector_ids;
      const nextLabel = sectorsLabel ? String(sectorsLabel).trim() : curr.sectors_label;
      const nextActive = isActive !== undefined ? Boolean(isActive) : Boolean(curr.is_active);

      const updRes = await db.query(
        `UPDATE irrigation_schedules
         SET scheduled_time = $1, sector_ids = $2, sectors_label = $3, is_active = $4, updated_at = NOW()
         WHERE id = $5
         RETURNING *`,
        [nextTime, nextIds, nextLabel, nextActive, id]
      );
      await syncNextActiveScheduleToSettings();
      return res.json(formatScheduleRow(updRes.rows[0]));
    }

    const item = fallbackSchedules.find(s => s.id === id);
    if (!item) return res.status(404).json({ error: 'Agendamento não encontrado' });
    item.time = String(time).trim();
    if (Array.isArray(sectorIds) && sectorIds.length > 0) item.sectorIds = sectorIds;
    if (sectorsLabel) item.sectorsLabel = String(sectorsLabel).trim();
    if (isActive !== undefined) item.isActive = Boolean(isActive);
    return res.json(item);
  } catch (error) {
    console.error('Error updating schedule item:', error);
    return res.status(500).json({ error: 'Erro ao editar agendamento' });
  }
};

exports.toggleScheduleItem = async (req, res) => {
  const { id } = req.params;
  const { isActive } = req.body || {};

  try {
    if (db.isDbConnected()) {
      const existingRes = await db.query('SELECT * FROM irrigation_schedules WHERE id = $1', [id]);
      if (existingRes.rows.length === 0) {
        return res.status(404).json({ error: 'Agendamento não encontrado' });
      }
      const curr = existingRes.rows[0];
      const nextActive = isActive !== undefined ? Boolean(isActive) : !Boolean(curr.is_active);

      const updRes = await db.query(
        'UPDATE irrigation_schedules SET is_active = $1, updated_at = NOW() WHERE id = $2 RETURNING *',
        [nextActive, id]
      );
      await syncNextActiveScheduleToSettings();
      return res.json(formatScheduleRow(updRes.rows[0]));
    }

    const item = fallbackSchedules.find(s => s.id === id);
    if (!item) return res.status(404).json({ error: 'Agendamento não encontrado' });
    item.isActive = isActive !== undefined ? Boolean(isActive) : !item.isActive;
    return res.json(item);
  } catch (error) {
    console.error('Error toggling schedule item:', error);
    return res.status(500).json({ error: 'Erro ao ativar/desativar agendamento' });
  }
};

exports.deleteScheduleItem = async (req, res) => {
  const { id } = req.params;

  try {
    if (db.isDbConnected()) {
      const delRes = await db.query('DELETE FROM irrigation_schedules WHERE id = $1 RETURNING *', [id]);
      if (delRes.rows.length === 0) {
        return res.status(404).json({ error: 'Agendamento não encontrado' });
      }
      await syncNextActiveScheduleToSettings();
      return res.json({ message: 'Agendamento excluído com sucesso', id });
    }

    const idx = fallbackSchedules.findIndex(s => s.id === id);
    if (idx === -1) return res.status(404).json({ error: 'Agendamento não encontrado' });
    fallbackSchedules.splice(idx, 1);
    return res.json({ message: 'Agendamento excluído com sucesso', id });
  } catch (error) {
    console.error('Error deleting schedule item:', error);
    return res.status(500).json({ error: 'Erro ao excluir agendamento' });
  }
};
