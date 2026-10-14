const express = require('express');
const router = express.Router();
const irrigationController = require('../controllers/irrigationController');

router.get('/settings', irrigationController.getSettings);
router.post('/emergency-stop', irrigationController.emergencyStop);
router.post('/resume', irrigationController.resumeSystem);
router.put('/mode', irrigationController.setMode);
router.put('/parameters', irrigationController.updateParameters);

module.exports = router;
