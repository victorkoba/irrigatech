const db = require('../config/db');

const fallbackReadings = [
  { time: '00h', moisture: 35.0 },
  { time: '03h', moisture: 38.0 },
  { time: '06h', moisture: 42.0 },
  { time: '09h', moisture: 50.0 },
  { time: '12h', moisture: 55.0 },
  { time: '15h', moisture: 48.0 },
  { time: '18h', moisture: 42.0 },
  { time: 'Agora', moisture: 45.0, isCurrent: true },
];

const fallbackWeekly = [
  { sector: 'Setor A', previousWeek: '120 m³', currentWeek: '105 m³', variation: '-12.5%', isDecrease: true },
  { sector: 'Setor B', previousWeek: '95 m³', currentWeek: '102 m³', variation: '+7.3%', isDecrease: false },
  { sector: 'Setor C', previousWeek: '150 m³', currentWeek: '148 m³', variation: '-1.3%', isDecrease: true },
];

exports.getSectorReadings = async (req, res) => {
  const { sectorId } = req.params;
  try {
    if (db.isDbConnected()) {
      const result = await db.query(
        'SELECT moisture, temperature, precipitation, recorded_at FROM sensor_readings WHERE sector_id = $1 ORDER BY recorded_at ASC LIMIT 24',
        [sectorId]
      );
      if (result.rows.length > 0) {
        return res.json(result.rows.map(r => ({
          time: new Date(r.recorded_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          moisture: parseFloat(r.moisture),
          temperature: parseFloat(r.temperature),
          precipitation: parseFloat(r.precipitation),
        })));
      }
    }
    return res.json(fallbackReadings);
  } catch (error) {
    console.error('Error fetching readings:', error);
    return res.json(fallbackReadings);
  }
};

exports.getWeeklyComparison = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query('SELECT * FROM weekly_consumption ORDER BY sector_name ASC');
      if (result.rows.length > 0) {
        return res.json(result.rows.map(r => ({
          sector: r.sector_name,
          previousWeek: `${r.previous_week_m3} m³`,
          currentWeek: `${r.current_week_m3} m³`,
          variation: `${r.variation_pct > 0 ? '+' : ''}${r.variation_pct}%`,
          isDecrease: r.is_decrease,
        })));
      }
    }
    return res.json(fallbackWeekly);
  } catch (error) {
    console.error('Error fetching weekly comparison:', error);
    return res.json(fallbackWeekly);
  }
};

exports.ingestSensorReading = async (req, res) => {
  const { sectorId, moisture, temperature, precipitation } = req.body;
  try {
    if (db.isDbConnected()) {
      const insert = await db.query(
        'INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation) VALUES ($1, $2, $3, $4) RETURNING *',
        [sectorId, moisture, temperature, precipitation || 0.0]
      );
      // Update sector current reading
      await db.query(
        'UPDATE sectors SET moisture = $1, temperature = $2, updated_at = NOW() WHERE id = $3',
        [moisture, temperature, sectorId]
      );
      return res.status(201).json(insert.rows[0]);
    }
    return res.status(201).json({ message: 'Leitura recebida (modo memória)', sectorId, moisture, temperature });
  } catch (error) {
    console.error('Error ingesting sensor reading:', error);
    return res.status(500).json({ error: 'Erro ao registrar leitura de sensor' });
  }
};
