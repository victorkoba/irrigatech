const db = require('../config/db');

let fallbackSectors = [
  { id: 'setor_a', name: 'Setor A', region: 'Norte', status: 'irrigating', flowRate: 45.0, moisture: 45.0, temperature: 28.0 },
  { id: 'setor_b', name: 'Setor B', region: 'Leste', status: 'idle', flowRate: 0.0, moisture: 60.0, temperature: 26.5 },
  { id: 'setor_c', name: 'Setor C', region: 'Sul', status: 'error', flowRate: 0.0, moisture: 18.0, temperature: 31.0, alertMessage: 'Vazamento Detectado' },
  { id: 'setor_d', name: 'Setor D', region: 'Oeste', status: 'idle', flowRate: 0.0, moisture: 52.0, temperature: 27.0 },
  { id: 'setor_e', name: 'Setor E', region: 'Central', status: 'idle', flowRate: 0.0, moisture: 58.0, temperature: 26.0 },
];

exports.stopAllFallbackSectors = () => {
  fallbackSectors.forEach(s => {
    if (s.status === 'irrigating') {
      s.status = 'idle';
      s.flowRate = 0.0;
    }
  });
};

exports.getAllSectors = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query('SELECT * FROM sectors ORDER BY name ASC');
      return res.json(result.rows.map(s => ({
        id: s.id,
        name: s.name,
        region: s.region,
        status: s.status,
        flowRate: parseFloat(s.flow_rate),
        moisture: parseFloat(s.moisture),
        temperature: parseFloat(s.temperature),
        alertMessage: s.alert_message,
      })));
    }
    return res.json(fallbackSectors);
  } catch (error) {
    console.error('Error fetching sectors:', error);
    return res.json(fallbackSectors);
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
        'UPDATE sectors SET status = $1, flow_rate = $2, updated_at = NOW() WHERE id = $3',
        [newStatus, newFlow, id]
      );

      // Record event
      if (isTurningOn) {
        await db.query(
          'INSERT INTO irrigation_events (sector_id, start_time, triggered_by) VALUES ($1, NOW(), $2)',
          [id, 'Manual / API']
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
      await db.query('UPDATE sectors SET flow_rate = $1, updated_at = NOW() WHERE id = $2', [rate, id]);
      return res.json({ id, flowRate: rate });
    }

    const sector = fallbackSectors.find(s => s.id === id);
    if (!sector) return res.status(404).json({ error: 'Setor não encontrado' });
    sector.flowRate = rate;
    return res.json(sector);
  } catch (error) {
    console.error('Error setting flow rate:', error);
    return res.status(500).json({ error: 'Falha ao alterar vazão' });
  }
};
