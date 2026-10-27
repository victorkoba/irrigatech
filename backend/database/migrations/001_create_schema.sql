-- ==========================================================
-- Migration 001: Schema Estrutural Completo do IrrigaTech
-- Tabelas com idempotência (CREATE TABLE IF NOT EXISTS)
-- ==========================================================

-- 1. Tabela de Usuários e Operadores de Campo
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'operator',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Configurações Globais e Automação
CREATE TABLE IF NOT EXISTS automation_settings (
    id SERIAL PRIMARY KEY,
    is_system_active BOOLEAN NOT NULL DEFAULT TRUE,
    operation_mode VARCHAR(20) NOT NULL DEFAULT 'Automático',
    min_moisture_trigger NUMERIC(5, 2) NOT NULL DEFAULT 30.00,
    max_moisture_cutoff NUMERIC(5, 2) NOT NULL DEFAULT 75.00,
    next_irrigation_time VARCHAR(10) DEFAULT '14:30',
    next_irrigation_sectors VARCHAR(100) DEFAULT 'Setores B e D (Milho)',
    daily_progress_pct NUMERIC(5, 2) DEFAULT 65.00,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Setores Agrícolas
CREATE TABLE IF NOT EXISTS sectors (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    crop VARCHAR(100) DEFAULT 'Milho',
    status VARCHAR(20) NOT NULL DEFAULT 'idle',
    flow_rate NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    moisture NUMERIC(5, 2) NOT NULL DEFAULT 45.00,
    temperature NUMERIC(5, 2) NOT NULL DEFAULT 28.00,
    alert_message VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Leituras de Sensores Telemétricos
CREATE TABLE IF NOT EXISTS sensor_readings (
    id BIGSERIAL PRIMARY KEY,
    sector_id VARCHAR(50) NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
    moisture NUMERIC(5, 2) NOT NULL,
    temperature NUMERIC(5, 2) NOT NULL,
    precipitation NUMERIC(5, 2) NOT NULL DEFAULT 0.00,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sensor_readings_sector_time ON sensor_readings(sector_id, recorded_at DESC);

-- 5. Alertas de Operação e Segurança
CREATE TABLE IF NOT EXISTS alerts (
    id VARCHAR(50) PRIMARY KEY,
    sector_id VARCHAR(50) REFERENCES sectors(id) ON DELETE SET NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'warning',
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Histórico de Eventos de Irrigação
CREATE TABLE IF NOT EXISTS irrigation_events (
    id SERIAL PRIMARY KEY,
    sector_id VARCHAR(50) NOT NULL REFERENCES sectors(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INT,
    water_volume_m3 NUMERIC(8, 2) DEFAULT 0.00,
    triggered_by VARCHAR(50) DEFAULT 'Automático'
);

-- 7. Métricas de Produtividade Agrícola
CREATE TABLE IF NOT EXISTS productivity_metrics (
    id SERIAL PRIMARY KEY,
    plot_label VARCHAR(50) NOT NULL,
    current_cycle_yield NUMERIC(6, 2) NOT NULL,
    previous_cycle_yield NUMERIC(6, 2) NOT NULL,
    crop VARCHAR(100) DEFAULT 'Milho',
    year INT DEFAULT 2026
);

-- 8. Comparativo de Consumo Semanal de Água
CREATE TABLE IF NOT EXISTS weekly_consumption (
    id SERIAL PRIMARY KEY,
    sector_name VARCHAR(100) NOT NULL,
    previous_week_m3 NUMERIC(8, 2) NOT NULL,
    current_week_m3 NUMERIC(8, 2) NOT NULL,
    variation_pct NUMERIC(5, 2) NOT NULL,
    is_decrease BOOLEAN NOT NULL DEFAULT TRUE
);
