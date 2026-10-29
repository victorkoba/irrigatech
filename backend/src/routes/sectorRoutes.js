const express = require('express');
const router = express.Router();
const sectorController = require('../controllers/sectorController');

router.get('/', sectorController.getAllSectors);
router.post('/', sectorController.createSector);
router.put('/:id', sectorController.updateSector);
router.put('/:id/enabled', sectorController.setSectorEnabled);
router.post('/:id/toggle', sectorController.toggleSector);
router.put('/:id/flow-rate', sectorController.setFlowRate);
router.delete('/:id', sectorController.deleteSector);

module.exports = router;
