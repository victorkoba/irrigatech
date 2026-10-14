const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const db = require('./config/db');

// Import routes
const dashboardRoutes = require('./routes/dashboardRoutes');
const sectorRoutes = require('./routes/sectorRoutes');
const irrigationRoutes = require('./routes/irrigationRoutes');
const monitoringRoutes = require('./routes/monitoringRoutes');
const reportRoutes = require('./routes/reportRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Health check & DB status
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    appName: 'IrrigaTech Backend API',
    version: '1.0.0',
    database: {
      connected: db.isDbConnected(),
      type: 'PostgreSQL',
      host: process.env.DB_HOST || 'localhost',
      database: process.env.DB_NAME || 'irrigatech',
      dbeaverReady: true,
    },
    timestamp: new Date().toISOString(),
  });
});

// Mount modular routes
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/sectors', sectorRoutes);
app.use('/api/irrigation', irrigationRoutes);
app.use('/api/monitoring', monitoringRoutes);
app.use('/api/reports', reportRoutes);

// Fallback 404
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint não encontrado', path: req.originalUrl });
});

app.listen(PORT, () => {
  console.log(`\n==================================================`);
  console.log(`🌱 IrrigaTech Backend rodando em http://localhost:${PORT}`);
  console.log(`📡 Endpoints disponíveis:`);
  console.log(`   - GET  /api/health`);
  console.log(`   - GET  /api/dashboard/summary`);
  console.log(`   - GET  /api/sectors`);
  console.log(`   - POST /api/sectors/:id/toggle`);
  console.log(`   - PUT  /api/sectors/:id/flow-rate`);
  console.log(`   - POST /api/irrigation/emergency-stop`);
  console.log(`   - PUT  /api/irrigation/mode`);
  console.log(`   - PUT  /api/irrigation/parameters`);
  console.log(`   - GET  /api/monitoring/readings/:sectorId`);
  console.log(`   - GET  /api/monitoring/weekly-comparison`);
  console.log(`   - GET  /api/reports/overview`);
  console.log(`==================================================\n`);
});
