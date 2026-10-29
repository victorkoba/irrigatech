const express = require('express');
const router = express.Router();
const monitoringController = require('../controllers/monitoringController');

router.get('/sector-summary/:sectorId', monitoringController.getSectorMonitoringSummary);
router.get('/readings/:sectorId', monitoringController.getSectorReadings);
router.get('/weekly-comparison', monitoringController.getWeeklyComparison);
router.post('/readings', monitoringController.ingestSensorReading);
router.post('/seed-history', monitoringController.seedHistoricalReadings);
router.delete('/clear', monitoringController.clearTelemetryData);

module.exports = router;
