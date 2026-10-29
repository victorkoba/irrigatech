const express = require('express');
const router = express.Router();
const irrigationController = require('../controllers/irrigationController');

router.get('/settings', irrigationController.getSettings);
router.post('/emergency-stop', irrigationController.emergencyStop);
router.post('/resume', irrigationController.resumeSystem);
router.put('/mode', irrigationController.setMode);
router.put('/parameters', irrigationController.updateParameters);
router.get('/schedule', irrigationController.getSchedule);
router.put('/schedule', irrigationController.updateSchedule);

// Múltiplos agendamentos de irrigação (adicionar, editar, ativar/desativar, excluir)
router.get('/schedules', irrigationController.getSchedules);
router.post('/schedules', irrigationController.createSchedule);
router.put('/schedules/:id', irrigationController.updateScheduleItem);
router.put('/schedules/:id/toggle', irrigationController.toggleScheduleItem);
router.delete('/schedules/:id', irrigationController.deleteScheduleItem);

module.exports = router;
