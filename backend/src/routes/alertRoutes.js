const express = require('express');
const router = express.Router();
const alertController = require('../controllers/alertController');

router.get('/', alertController.getAllAlerts);
router.post('/', alertController.createAlert);
router.put('/:id/resolve', alertController.resolveAlert);
router.delete('/:id', alertController.deleteAlert);

module.exports = router;
