-- ==========================================================
-- 🌱 IrrigaTech - Database Schema (PostgreSQL)
-- Compatible with DBeaver, pgAdmin, and psql
-- ==========================================================

-- Drop tables if they exist (for clean initialization)
DROP TABLE IF EXISTS weekly_consumption CASCADE;
DROP TABLE IF EXISTS productivity_metrics CASCADE;
DROP TABLE IF EXISTS irrigation_events CASCADE;
DROP TABLE IF EXISTS sensor_readings CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS sectors CASCADE;
DROP TABLE IF EXISTS automation_settings CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 0. Users & Authentication
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'operator',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 1. Automation & System Settings
CREATE TABLE automation_settings (
    id SERIAL PRIMARY KEY,
    is_system_active BOOLEAN NOT NULL DEFAULT TRUE,
    operation_mode VARCHAR(20) NOT NULL DEFAULT 'Automático', -- 'Automático' or 'Manual'
    min_moisture_trigger NUMERIC(5, 2) NOT NULL DEFAULT 30.00,
    max_moisture_cutoff NUMERIC(5, 2) NOT NULL DEFAULT 75.00,
    next_irrigation_time VARCHAR(10) DEFAULT '14:30',
    next_irrigation_sectors VARCHAR(100) DEFAULT 'Setores B e D (Milho)',
    daily_progress_pct NUMERIC(5, 2) DEFAULT 65.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Agricultural Sectors
CREATE TABLE sectors (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    crop VARCHAR(100) DEFAULT 'Milho',
    status VARCHAR(20) NOT NULL DEFAULT 'idle', -- 'irrigating', 'idle', 'error'
    flow_rate NUMERIC(6, 2) NOT NULL DEFAULT 0.00, -- m³/h
    moisture NUMERIC(5, 2) NOT NULL DEFAULT 45.00, -- %
    temperature NUMERIC(5, 2) NOT NULL DEFAULT 28.00, -- °C
    alert_message VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Real-Time & Historical Sensor Readings
CREATE TABLE sensor_readings (
    id BIGSERIAL PRIMARY KEY,
    sector_id VARCHAR(50) NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
    moisture NUMERIC(5, 2) NOT NULL,
    temperature NUMERIC(5, 2) NOT NULL,
    precipitation NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast time-series queries
CREATE INDEX idx_sensor_readings_sector_time ON sensor_readings(sector_id, recorded_at DESC);

-- 4. Alerts
CREATE TABLE alerts (
    id VARCHAR(50) PRIMARY KEY,
    sector_id VARCHAR(50) REFERENCES sectors(id) ON DELETE SET NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'warning', -- 'critical', 'warning', 'info'
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Irrigation History & Events
CREATE TABLE irrigation_events (
    id SERIAL PRIMARY KEY,
    sector_id VARCHAR(50) NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INT,
    water_volume_m3 NUMERIC(8, 2) DEFAULT 0.00,
    triggered_by VARCHAR(50) DEFAULT 'Automático' -- 'Automático', 'Manual', 'Agendamento'
);

-- 6. Productivity Comparison Metrics (Sacas/ha)
CREATE TABLE productivity_metrics (
    id SERIAL PRIMARY KEY,
    plot_label VARCHAR(50) NOT NULL, -- 'Talhão A', 'Talhão B', etc.
    current_cycle_yield NUMERIC(6, 2) NOT NULL,
    previous_cycle_yield NUMERIC(6, 2) NOT NULL,
    crop VARCHAR(100) DEFAULT 'Milho',
    year INT DEFAULT 2026
);

-- 7. Weekly Water Consumption Comparison
CREATE TABLE weekly_consumption (
    id SERIAL PRIMARY KEY,
    sector_name VARCHAR(50) NOT NULL,
    previous_week_m3 NUMERIC(8, 2) NOT NULL,
    current_week_m3 NUMERIC(8, 2) NOT NULL,
    variation_pct NUMERIC(5, 2) NOT NULL,
    is_decrease BOOLEAN NOT NULL DEFAULT TRUE
);

-- ==========================================================
-- 🌾 Initial Seed Data
-- ==========================================================

-- Default Users (Password: 123456)
INSERT INTO users (name, email, password_hash, role) VALUES
('Operador IrrigaTech', 'operador@irrigatech.com', '$2b$10$iCAmiKUfYuCnsZqcu9xeVO0wPMhAzVDHR4RNPI0H0e2ALNUiHZ2F2', 'operator'),
('Administrador', 'admin@irrigatech.com', '$2b$10$iCAmiKUfYuCnsZqcu9xeVO0wPMhAzVDHR4RNPI0H0e2ALNUiHZ2F2', 'admin');

-- Settings
INSERT INTO automation_settings (is_system_active, operation_mode, min_moisture_trigger, max_moisture_cutoff, next_irrigation_time, next_irrigation_sectors, daily_progress_pct)
VALUES (TRUE, 'Automático', 30.00, 75.00, '14:30', 'Setores B e D (Milho)', 65.00);

-- Sectors
INSERT INTO sectors (id, name, region, crop, status, flow_rate, moisture, temperature, alert_message) VALUES
('setor_a', 'Setor A', 'Norte', 'Soja', 'irrigating', 45.00, 45.00, 28.00, NULL),
('setor_b', 'Setor B', 'Leste', 'Milho', 'idle', 0.00, 60.00, 26.50, NULL),
('setor_c', 'Setor C', 'Sul', 'Café', 'error', 0.00, 18.00, 31.00, 'Vazamento Detectado'),
('setor_d', 'Setor D', 'Oeste', 'Algodão', 'idle', 0.00, 52.00, 27.00, NULL),
('setor_e', 'Setor E', 'Central', 'Milho', 'idle', 0.00, 58.00, 26.00, NULL);

-- Active Alerts
INSERT INTO alerts (id, sector_id, title, description, severity, is_resolved) VALUES
('alert_1', 'setor_a', 'Umidade baixa no Setor A', 'Níveis abaixo de 15%. Irrigação de emergência recomendada.', 'critical', FALSE),
('alert_2', 'setor_c', 'Vazamento detectado no Setor C', 'Pressão anormal na linha principal detectada há 10 min.', 'warning', FALSE);

-- Hourly Readings (24h snapshot for Sector A)
INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, recorded_at) VALUES
('setor_a', 35.0, 24.0, 0.0, NOW() - INTERVAL '21 hours'),
('setor_a', 38.0, 23.5, 0.0, NOW() - INTERVAL '18 hours'),
('setor_a', 42.0, 25.0, 0.0, NOW() - INTERVAL '15 hours'),
('setor_a', 50.0, 27.0, 0.0, NOW() - INTERVAL '12 hours'),
('setor_a', 55.0, 29.5, 0.0, NOW() - INTERVAL '9 hours'),
('setor_a', 48.0, 28.0, 1.0, NOW() - INTERVAL '6 hours'),
('setor_a', 42.0, 27.5, 1.0, NOW() - INTERVAL '3 hours'),
('setor_a', 45.0, 28.0, 2.0, NOW());

-- Productivity Comparison Data
INSERT INTO productivity_metrics (plot_label, current_cycle_yield, previous_cycle_yield, crop) VALUES
('Talhão A', 68.0, 60.0, 'Soja'),
('Talhão B', 74.0, 64.0, 'Milho'),
('Talhão C', 56.0, 52.0, 'Café'),
('Talhão D', 78.0, 68.0, 'Algodão');

-- Weekly Consumption Comparison
INSERT INTO weekly_consumption (sector_name, previous_week_m3, current_week_m3, variation_pct, is_decrease) VALUES
('Setor A', 120.0, 105.0, -12.5, TRUE),
('Setor B', 95.0, 102.0, 7.3, FALSE),
('Setor C', 150.0, 148.0, -1.3, TRUE);
