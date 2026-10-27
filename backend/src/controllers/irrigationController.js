const db = require('../config/db');
const sectorController = require('./sectorController');

let fallbackSettings = {
  isSystemActive: true,
  operationMode: 'Automático',
  minMoistureTrigger: 30.0,
  maxMoistureCutoff: 75.0,
};

exports.getSettings = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query('SELECT * FROM automation_settings LIMIT 1');
      if (result.rows.length > 0) {
        const s = result.rows[0];
        return res.json({
          isSystemActive: s.is_system_active,
          operationMode: s.operation_mode,
          minMoistureTrigger: parseFloat(s.min_moisture_trigger),
          maxMoistureCutoff: parseFloat(s.max_moisture_cutoff),
        });
      }
    }
    return res.json(fallbackSettings);
  } catch (error) {
    console.error('Error fetching settings:', error);
    return res.json(fallbackSettings);
  }
};

exports.emergencyStop = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      await db.query('UPDATE automation_settings SET is_system_active = false, updated_at = NOW()');
      await db.query("UPDATE sectors SET status = 'idle', flow_rate = 0 WHERE status = 'irrigating'");
      return res.json({ message: 'Parada de emergência executada.', isSystemActive: false });
    }
    fallbackSettings.isSystemActive = false;
    sectorController.stopAllFallbackSectors();
    return res.json({ message: 'Parada de emergência executada.', isSystemActive: false });
  } catch (error) {
    console.error('Error executing emergency stop:', error);
    return res.status(500).json({ error: 'Erro ao executar parada de emergência' });
  }
};

exports.resumeSystem = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      await db.query('UPDATE automation_settings SET is_system_active = true, updated_at = NOW()');
      return res.json({ message: 'Sistema reativado.', isSystemActive: true });
    }
    fallbackSettings.isSystemActive = true;
    return res.json({ message: 'Sistema reativado.', isSystemActive: true });
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
