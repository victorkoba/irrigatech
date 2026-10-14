const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');

router.get('/overview', reportController.getReportsOverview);
router.get('/export/:id', reportController.downloadReport);

module.exports = router;
