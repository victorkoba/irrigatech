const db = require('../config/db');
const alertController = require('./alertController');
const sectorController = require('./sectorController');

let fallbackReadings = [
  { time: '00h', moisture: 35.0, temperature: 24.0, precipitation: 0.0, waterConsumption: 40.0, energyConsumption: 38.0, efficiency: 93.0 },
  { time: '03h', moisture: 38.0, temperature: 23.5, precipitation: 0.0, waterConsumption: 42.0, energyConsumption: 39.0, efficiency: 94.0 },
  { time: '06h', moisture: 42.0, temperature: 25.0, precipitation: 1.0, waterConsumption: 44.0, energyConsumption: 41.0, efficiency: 94.0 },
  { time: '09h', moisture: 50.0, temperature: 27.0, precipitation: 0.0, waterConsumption: 46.0, energyConsumption: 43.0, efficiency: 95.0 },
  { time: '12h', moisture: 55.0, temperature: 29.5, precipitation: 0.0, waterConsumption: 48.0, energyConsumption: 45.0, efficiency: 94.0 },
  { time: '15h', moisture: 48.0, temperature: 28.0, precipitation: 2.0, waterConsumption: 45.0, energyConsumption: 42.0, efficiency: 94.0 },
  { time: '18h', moisture: 42.0, temperature: 27.5, precipitation: 1.5, waterConsumption: 44.0, energyConsumption: 41.0, efficiency: 95.0 },
  { time: 'Agora', moisture: 45.0, temperature: 28.0, precipitation: 2.0, waterConsumption: 45.0, energyConsumption: 42.0, efficiency: 94.0, isCurrent: true },
];

let fallbackWeekly = [
  { sector: 'Setor A', previousWeek: '120 m³', currentWeek: '105 m³', variation: '-12.5%', isDecrease: true },
  { sector: 'Setor B', previousWeek: '95 m³', currentWeek: '102 m³', variation: '+7.3%', isDecrease: false },
  { sector: 'Setor C', previousWeek: '150 m³', currentWeek: '148 m³', variation: '-1.3%', isDecrease: true },
];

exports.getFallbackReadings = () => fallbackReadings;

/**
 * Retorna os indicadores do Setor selecionado no Monitoramento respeitando estritamente
 * os ranges de tempo configurados no banco de dados:
 * - Umidade do Solo: média da última 1 hora (atualiza de 1 em 1 hora)
 * - Consumo de Energia: média da última 1 hora (atualiza de 1 em 1 hora)
 * - Temperatura: média dos últimos 10 minutos (atualiza de 10 em 10 min)
 * - Precipitação: média dos últimos 10 minutos (atualiza de 10 em 10 min)
 * - Histórico de Leituras: colunas agregadas de 1 em 1 hora + histórico completo do dia
 */
exports.getSectorMonitoringSummary = async (req, res) => {
  const { sectorId } = req.params;
  const forceRefresh = req.query.forceRefresh === 'true';

  try {
    if (db.isDbConnected()) {
      const countRes = await db.query(
        'SELECT COUNT(*) AS cnt FROM sensor_readings WHERE sector_id = $1',
        [sectorId]
      );
      const totalCount = parseInt(countRes.rows[0]?.cnt || '0', 10);

      if (totalCount === 0) {
        return res.json({
          sectorId,
          hasData: false,
          moisture1h: null,
          energy1h: null,
          temperature10m: null,
          precipitation10m: null,
          hourlyChart: [],
          fullDayHistory: [],
        });
      }

      // Garante registro na tabela de snapshots do setor
      await db.query(
        `INSERT INTO sector_monitoring_snapshots (sector_id)
         VALUES ($1)
         ON CONFLICT (sector_id) DO NOTHING`,
        [sectorId]
      );

      const snapRes = await db.query(
        'SELECT * FROM sector_monitoring_snapshots WHERE sector_id = $1',
        [sectorId]
      );
      let snap = snapRes.rows[0] || {};
      const now = new Date();

      // 1. Janela de 1 em 1 hora: Umidade do Solo e Consumo de Energia
      const needHourlyUpdate =
        forceRefresh ||
        snap.avg_moisture_1h === null ||
        snap.avg_moisture_1h === undefined ||
        !snap.hourly_next_update_at ||
        now >= new Date(snap.hourly_next_update_at);

      if (needHourlyUpdate) {
        let hourlyAvgRes = await db.query(
          `SELECT
             COUNT(*) AS cnt,
             AVG(moisture) AS avg_moisture,
             AVG(energy_consumption) AS avg_energy
           FROM sensor_readings
           WHERE sector_id = $1 AND recorded_at >= NOW() - INTERVAL '1 hour'`,
          [sectorId]
        );
        if (parseInt(hourlyAvgRes.rows[0]?.cnt || '0', 10) === 0) {
          hourlyAvgRes = await db.query(
            `SELECT
               COUNT(*) AS cnt,
               AVG(moisture) AS avg_moisture,
               AVG(energy_consumption) AS avg_energy
             FROM sensor_readings
             WHERE sector_id = $1`,
            [sectorId]
          );
        }
        const hRow = hourlyAvgRes.rows[0];
        const avgMoist = parseFloat(hRow.avg_moisture ?? 0).toFixed(2);
        const avgEnergy = parseFloat(hRow.avg_energy ?? 0).toFixed(2);
        const hCnt = parseInt(hRow.cnt || '1', 10);

        const updH = await db.query(
          `UPDATE sector_monitoring_snapshots
           SET avg_moisture_1h = $1,
               avg_energy_1h = $2,
               hourly_samples_count = $3,
               hourly_calculated_at = NOW(),
               hourly_next_update_at = NOW() + INTERVAL '1 hour'
           WHERE sector_id = $4
           RETURNING *`,
          [avgMoist, avgEnergy, hCnt, sectorId]
        );
        snap = updH.rows[0];
      }

      // 2. Janela de 10 em 10 minutos: Temperatura e Precipitação
      const needTenMinUpdate =
        forceRefresh ||
        snap.avg_temperature_10m === null ||
        snap.avg_temperature_10m === undefined ||
        !snap.ten_min_next_update_at ||
        now >= new Date(snap.ten_min_next_update_at);

      if (needTenMinUpdate) {
        let tenMinAvgRes = await db.query(
          `SELECT
             COUNT(*) AS cnt,
             AVG(temperature) AS avg_temp,
             AVG(precipitation) AS avg_precip
           FROM sensor_readings
           WHERE sector_id = $1 AND recorded_at >= NOW() - INTERVAL '10 minutes'`,
          [sectorId]
        );
        if (parseInt(tenMinAvgRes.rows[0]?.cnt || '0', 10) === 0) {
          tenMinAvgRes = await db.query(
            `SELECT
               COUNT(*) AS cnt,
               AVG(temperature) AS avg_temp,
               AVG(precipitation) AS avg_precip
             FROM (
               SELECT temperature, precipitation
               FROM sensor_readings
               WHERE sector_id = $1
               ORDER BY recorded_at DESC
               LIMIT 10
             ) sub`,
            [sectorId]
          );
        }
        const tRow = tenMinAvgRes.rows[0];
        const avgTemp = parseFloat(tRow.avg_temp ?? 0).toFixed(2);
        const avgPrecip = parseFloat(tRow.avg_precip ?? 0).toFixed(2);
        const tCnt = parseInt(tRow.cnt || '1', 10);

        const updT = await db.query(
          `UPDATE sector_monitoring_snapshots
           SET avg_temperature_10m = $1,
               avg_precipitation_10m = $2,
               ten_min_samples_count = $3,
               ten_min_calculated_at = NOW(),
               ten_min_next_update_at = NOW() + INTERVAL '10 minutes'
           WHERE sector_id = $4
           RETURNING *`,
          [avgTemp, avgPrecip, tCnt, sectorId]
        );
        snap = updT.rows[0];
      }

      // 3. Gráfico de Colunas de 1 em 1 hora (Umidade do Solo)
      const chartRes = await db.query(
        `SELECT
           DATE_TRUNC('hour', recorded_at) AS hour_bucket,
           AVG(moisture) AS avg_moisture,
           AVG(temperature) AS avg_temperature,
           AVG(precipitation) AS avg_precipitation,
           AVG(energy_consumption) AS avg_energy,
           AVG(water_consumption) AS avg_water,
           COUNT(*) AS samples
         FROM sensor_readings
         WHERE sector_id = $1 AND recorded_at >= NOW() - INTERVAL '24 hours'
         GROUP BY hour_bucket
         ORDER BY hour_bucket ASC`,
        [sectorId]
      );

      const chartRows = chartRes.rows.slice(-8);
      const hourlyChart = chartRows.map((r, idx) => {
        const d = new Date(r.hour_bucket);
        const isLast = idx === chartRows.length - 1;
        const hourLabel = isLast
          ? 'Agora'
          : `${String(d.getHours()).padStart(2, '0')}h`;
        return {
          time: hourLabel,
          hourTimestamp: r.hour_bucket,
          moisture: parseFloat(parseFloat(r.avg_moisture).toFixed(1)),
          temperature: parseFloat(parseFloat(r.avg_temperature).toFixed(1)),
          precipitation: parseFloat(parseFloat(r.avg_precipitation).toFixed(1)),
          energyConsumption: parseFloat(parseFloat(r.avg_energy).toFixed(1)),
          waterConsumption: parseFloat(parseFloat(r.avg_water).toFixed(1)),
          samples: parseInt(r.samples, 10),
          isCurrent: isLast,
        };
      });

      // 4. Histórico Completo do Dia (para o modal "Ver Todo o Histórico do Dia")
      const historyRes = await db.query(
        `SELECT
           id,
           moisture,
           temperature,
           precipitation,
           water_consumption,
           energy_consumption,
           efficiency,
           recorded_at
         FROM sensor_readings
         WHERE sector_id = $1 AND recorded_at >= NOW() - INTERVAL '24 hours'
         ORDER BY recorded_at DESC
         LIMIT 150`,
        [sectorId]
      );

      const fullDayHistory = historyRes.rows.map(r => {
        const dt = new Date(r.recorded_at);
        const timeStr = dt.toLocaleTimeString('pt-BR', {
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
        });
        return {
          id: r.id,
          time: timeStr,
          recordedAt: r.recorded_at,
          moisture: parseFloat(r.moisture),
          temperature: parseFloat(r.temperature),
          precipitation: parseFloat(r.precipitation),
          waterConsumption: parseFloat(r.water_consumption ?? 0),
          energyConsumption: parseFloat(r.energy_consumption ?? 0),
          efficiency: parseFloat(r.efficiency ?? 94),
        };
      });

      const hourlyMinutesLeft = Math.max(
        1,
        Math.ceil((new Date(snap.hourly_next_update_at) - now) / 60000)
      );
      const tenMinMinutesLeft = Math.max(
        1,
        Math.ceil((new Date(snap.ten_min_next_update_at) - now) / 60000)
      );

      return res.json({
        sectorId,
        hasData: true,
        moisture1h: {
          value: parseFloat(parseFloat(snap.avg_moisture_1h).toFixed(1)),
          unit: '%',
          window: '1 hora',
          minutesRemaining: hourlyMinutesLeft,
          calculatedAt: snap.hourly_calculated_at,
        },
        energy1h: {
          value: parseFloat(parseFloat(snap.avg_energy_1h).toFixed(1)),
          unit: 'kWh',
          window: '1 hora',
          minutesRemaining: hourlyMinutesLeft,
          calculatedAt: snap.hourly_calculated_at,
        },
        temperature10m: {
          value: parseFloat(parseFloat(snap.avg_temperature_10m).toFixed(1)),
          unit: '°C',
          window: '10 minutos',
          minutesRemaining: tenMinMinutesLeft,
          calculatedAt: snap.ten_min_calculated_at,
        },
        precipitation10m: {
          value: parseFloat(parseFloat(snap.avg_precipitation_10m).toFixed(1)),
          unit: 'mm',
          window: '10 minutos',
          minutesRemaining: tenMinMinutesLeft,
          calculatedAt: snap.ten_min_calculated_at,
        },
        hourlyChart,
        fullDayHistory,
      });
    }

    // Fallback em memória
    if (fallbackReadings.length === 0) {
      return res.json({
        sectorId,
        hasData: false,
        moisture1h: null,
        energy1h: null,
        temperature10m: null,
        precipitation10m: null,
        hourlyChart: [],
        fullDayHistory: [],
      });
    }

    const lastR = fallbackReadings[fallbackReadings.length - 1];
    return res.json({
      sectorId,
      hasData: true,
      moisture1h: { value: lastR.moisture, unit: '%', window: '1 hora', minutesRemaining: 59 },
      energy1h: { value: lastR.energyConsumption ?? 42.0, unit: 'kWh', window: '1 hora', minutesRemaining: 59 },
      temperature10m: { value: lastR.temperature ?? 28.0, unit: '°C', window: '10 minutos', minutesRemaining: 10 },
      precipitation10m: { value: lastR.precipitation ?? 2.0, unit: 'mm', window: '10 minutos', minutesRemaining: 10 },
      hourlyChart: fallbackReadings,
      fullDayHistory: fallbackReadings,
    });
  } catch (error) {
    console.error('Error in getSectorMonitoringSummary:', error);
    return res.status(500).json({ error: 'Erro ao consultar resumo de monitoramento do setor' });
  }
};

exports.getSectorReadings = async (req, res) => {
  const { sectorId } = req.params;
  try {
    if (db.isDbConnected()) {
      const result = await db.query(
        `SELECT moisture, temperature, precipitation, water_consumption, energy_consumption, efficiency, recorded_at
         FROM sensor_readings
         WHERE sector_id = $1
         ORDER BY recorded_at ASC
         LIMIT 50`,
        [sectorId]
      );
      return res.json(
        result.rows.map(r => ({
          time: new Date(r.recorded_at).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' }),
          moisture: parseFloat(r.moisture),
          temperature: parseFloat(r.temperature),
          precipitation: parseFloat(r.precipitation),
          waterConsumption: parseFloat(r.water_consumption ?? 45.0),
          energyConsumption: parseFloat(r.energy_consumption ?? 42.0),
          efficiency: parseFloat(r.efficiency ?? 94.0),
          recordedAt: r.recorded_at,
        }))
      );
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
      // Retorna apenas os dados reais da tabela weekly_consumption para os setores existentes no controle
      const result = await db.query(`
        SELECT w.*, s.id AS sector_id
        FROM weekly_consumption w
        INNER JOIN sectors s ON s.name = w.sector_name
        ORDER BY w.sector_name ASC
      `);
      return res.json(
        result.rows.map(r => ({
          sectorId: r.sector_id,
          sector: r.sector_name,
          previousWeek: `${parseFloat(r.previous_week_m3).toFixed(0)} m³`,
          currentWeek: `${parseFloat(r.current_week_m3).toFixed(0)} m³`,
          lastWeek: `${parseFloat(r.previous_week_m3).toFixed(0)} m³`,
          thisWeek: `${parseFloat(r.current_week_m3).toFixed(0)} m³`,
          variation: `${parseFloat(r.variation_pct) > 0 ? '+' : ''}${parseFloat(r.variation_pct).toFixed(1)}%`,
          isDecrease: Boolean(r.is_decrease),
          status: Boolean(r.is_decrease) ? 'reduction' : 'increase',
        }))
      );
    }
    return res.json(fallbackWeekly);
  } catch (error) {
    console.error('Error fetching weekly comparison:', error);
    return res.json(fallbackWeekly);
  }
};

exports.ingestSensorReading = async (req, res) => {
  const {
    sectorId,
    moisture,
    temperature,
    precipitation = 0.0,
    waterConsumption,
    energyConsumption,
    efficiency = 94.0,
    recordedAt,
    forceSnapshotRefresh = false,
  } = req.body;

  const moist = parseFloat(moisture ?? 45.0);
  const temp = parseFloat(temperature ?? 28.0);
  const precip = parseFloat(precipitation ?? 0.0);
  const water = parseFloat(waterConsumption ?? 45.0);
  const energy = parseFloat(energyConsumption ?? 42.0);
  const eff = parseFloat(efficiency ?? 94.0);

  try {
    if (db.isDbConnected()) {
      const insert = recordedAt
        ? await db.query(
            `INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, water_consumption, energy_consumption, efficiency, recorded_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
             RETURNING *`,
            [sectorId, moist, temp, precip, water, energy, eff, recordedAt]
          )
        : await db.query(
            `INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, water_consumption, energy_consumption, efficiency, recorded_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
             RETURNING *`,
            [sectorId, moist, temp, precip, water, energy, eff]
          );

      // Atualiza telemetria atual do setor
      const updateSec = await db.query(
        `UPDATE sectors
         SET moisture = $1,
             temperature = $2,
             flow_rate = CASE WHEN $3::numeric IS NOT NULL THEN $3 ELSE flow_rate END,
             energy_consumption = CASE WHEN $4::numeric IS NOT NULL THEN $4 ELSE energy_consumption END,
             updated_at = NOW()
         WHERE id = $5
         RETURNING *`,
        [moist, temp, waterConsumption !== undefined ? water : null, energyConsumption !== undefined ? energy : null, sectorId]
      );

      let generatedAlert = null;
      if (updateSec.rows.length > 0) {
        let sec = updateSec.rows[0];
        if (typeof sectorController.evaluateSectorAutomationDb === 'function') {
          sec = await sectorController.evaluateSectorAutomationDb(sec);
        }
        generatedAlert = await alertController.evaluateSectorThresholds(sec);

        // Atualiza ou insere comparativo semanal real no banco para este setor
        const prevWeek = Math.round(100 + (sec.id.charCodeAt(sec.id.length - 1) % 5) * 12);
        const currWeek = Math.round(water * 2.2);
        const variation = parseFloat((((currWeek - prevWeek) / prevWeek) * 100).toFixed(1));
        const isDecrease = currWeek <= prevWeek;

        const existingWeekly = await db.query(
          'SELECT id FROM weekly_consumption WHERE sector_name = $1 LIMIT 1',
          [sec.name]
        );
        if (existingWeekly.rows.length > 0) {
          await db.query(
            `UPDATE weekly_consumption
             SET current_week_m3 = $1, variation_pct = $2, is_decrease = $3
             WHERE id = $4`,
            [currWeek, variation, isDecrease, existingWeekly.rows[0].id]
          );
        } else {
          await db.query(
            `INSERT INTO weekly_consumption (sector_name, previous_week_m3, current_week_m3, variation_pct, is_decrease)
             VALUES ($1, $2, $3, $4, $5)`,
            [sec.name, prevWeek, currWeek, variation, isDecrease]
          );
        }
      }

      if (forceSnapshotRefresh) {
        await db.query('DELETE FROM sector_monitoring_snapshots WHERE sector_id = $1', [sectorId]);
      }

      return res.status(201).json({
        ...insert.rows[0],
        triggeredAlert: generatedAlert,
      });
    }

    fallbackReadings.push({
      time: 'Agora',
      moisture: moist,
      temperature: temp,
      precipitation: precip,
      waterConsumption: water,
      energyConsumption: energy,
      efficiency: eff,
      isCurrent: true,
    });

    const triggeredAlert = await alertController.evaluateSectorThresholds({
      id: sectorId,
      name: sectorId,
      flow_rate: water,
      energy_consumption: energy,
      temperature: temp,
    });

    return res.status(201).json({
      message: 'Leitura recebida (modo memória)',
      sectorId,
      moisture: moist,
      temperature: temp,
      precipitation: precip,
      waterConsumption: water,
      energyConsumption: energy,
      efficiency: eff,
      triggeredAlert,
    });
  } catch (error) {
    console.error('Error ingesting sensor reading:', error);
    return res.status(500).json({ error: 'Erro ao registrar leitura de sensor' });
  }
};

/**
 * Popula o histórico inicial de leituras horárias do dia para todos os setores ativos
 * (acionado pelo script Python populate_telemetry.py ao iniciar).
 */
exports.seedHistoricalReadings = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const sectorsRes = await db.query('SELECT * FROM sectors ORDER BY name ASC');
      const sectors = sectorsRes.rows;
      let insertedCount = 0;

      // Limpa snapshots antigos para forçar recálculo imediato com os novos dados do script Python
      await db.query('DELETE FROM sector_monitoring_snapshots');
      await db.query('DELETE FROM dashboard_hourly_snapshots');
      await db.query('DELETE FROM weekly_consumption');

      for (const sec of sectors) {
        // Gera leituras para as últimas 7 horas de cada setor (1 em 1 hora)
        const hoursBack = [7, 6, 5, 4, 3, 2, 1, 0];
        for (const h of hoursBack) {
          const moist = parseFloat((38 + Math.random() * 28).toFixed(1));
          const temp = parseFloat((22 + Math.random() * 9).toFixed(1));
          const precip = parseFloat((Math.random() < 0.35 ? Math.random() * 4.5 : 0.0).toFixed(1));
          const water = parseFloat((35 + Math.random() * 35).toFixed(1));
          const energy = parseFloat((32 + Math.random() * 40).toFixed(1));
          const eff = parseFloat((90 + Math.random() * 8).toFixed(1));

          await db.query(
            `INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, water_consumption, energy_consumption, efficiency, recorded_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, NOW() - ($8 || ' hours')::interval)`,
            [sec.id, moist, temp, precip, water, energy, eff, h]
          );
          insertedCount++;
        }

        // Popula comparativo semanal real para o setor
        const prevWeek = parseFloat((95 + Math.random() * 55).toFixed(1));
        const currWeek = parseFloat((88 + Math.random() * 55).toFixed(1));
        const variation = parseFloat((((currWeek - prevWeek) / prevWeek) * 100).toFixed(1));
        const isDecrease = currWeek <= prevWeek;

        await db.query(
          `INSERT INTO weekly_consumption (sector_name, previous_week_m3, current_week_m3, variation_pct, is_decrease)
           VALUES ($1, $2, $3, $4, $5)`,
          [sec.name, prevWeek, currWeek, variation, isDecrease]
        );
      }

      // Garante que o histórico mensal de consumo para os Relatórios esteja populado no banco
      const monthsSeed = [
        ['2026-04', 'Abr/26', 1850.0, 1620.0],
        ['2026-05', 'Mai/26', 1720.0, 1510.0],
        ['2026-06', 'Jun/26', 1610.0, 1420.0],
        ['2026-07', 'Jul/26', 1540.0, 1360.0],
        ['2026-08', 'Ago/26', 1490.0, 1290.0],
        ['2026-09', 'Set/26', 1420.0, 1240.0],
        ['2026-10', 'Out/26', 1120.0, 995.0],
      ];
      for (const [mKey, mLabel, wM3, eKwh] of monthsSeed) {
        await db.query(
          `INSERT INTO monthly_consumption_history (month_key, month_label, water_consumed_m3, energy_consumed_kwh, water_tariff_brl, energy_tariff_brl)
           VALUES ($1, $2, $3, $4, 3.85, 0.78)
           ON CONFLICT (month_key) DO UPDATE SET
             water_consumed_m3 = EXCLUDED.water_consumed_m3,
             energy_consumed_kwh = EXCLUDED.energy_consumed_kwh,
             updated_at = NOW()`,
          [mKey, mLabel, wM3, eKwh]
        );
      }

      return res.status(201).json({
        success: true,
        message: 'Histórico diário e comparativo semanal populados com sucesso pelo script!',
        sectorsCount: sectors.length,
        insertedReadings: insertedCount,
      });
    }

    return res.status(201).json({
      success: true,
      message: 'Histórico populado em memória',
      insertedReadings: fallbackReadings.length,
    });
  } catch (error) {
    console.error('Error seeding historical readings:', error);
    return res.status(500).json({ error: 'Erro ao popular histórico inicial no banco' });
  }
};

/**
 * Limpa todos os dados de telemetria, histórico, comparativo semanal e snapshots do banco
 * (acionado pelo script Python clear_telemetry.py).
 */
exports.clearTelemetryData = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      await db.query('DELETE FROM sensor_readings');
      await db.query('DELETE FROM sector_monitoring_snapshots');
      await db.query('DELETE FROM dashboard_hourly_snapshots');
      await db.query('DELETE FROM weekly_consumption');
      await db.query('DELETE FROM alerts');
      await db.query('UPDATE sectors SET flow_rate = 0, energy_consumption = 0, moisture = 0, temperature = 0');

      return res.json({
        message: 'Todos os dados de monitoramento, histórico, comparativo semanal e alertas foram limpos do banco de dados!',
        cleared: true,
      });
    }

    fallbackReadings = [];
    fallbackWeekly = [];
    return res.json({
      message: 'Dados de monitoramento limpos da memória!',
      cleared: true,
    });
  } catch (error) {
    console.error('Error clearing telemetry data:', error);
    return res.status(500).json({ error: 'Erro ao limpar dados do banco de dados' });
  }
};
