const express = require('express');
const router = express.Router();
const sectorController = require('../controllers/sectorController');

router.get('/', sectorController.getAllSectors);
router.post('/:id/toggle', sectorController.toggleSector);
router.put('/:id/flow-rate', sectorController.setFlowRate);

module.exports = router;
