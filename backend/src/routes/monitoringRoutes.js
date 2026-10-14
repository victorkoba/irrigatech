const express = require('express');
const router = express.Router();
const monitoringController = require('../controllers/monitoringController');

router.get('/readings/:sectorId', monitoringController.getSectorReadings);
router.get('/weekly-comparison', monitoringController.getWeeklyComparison);
router.post('/readings', monitoringController.ingestSensorReading);

module.exports = router;
