-- ==========================================================
-- 🌱 IrrigaTech - Database Seeder (SQL)
-- Execute este arquivo no DBeaver (Alt + X) para popular
-- o banco com dados realistas de IoT e Agronegócio.
-- ==========================================================

BEGIN;

-- 1. Limpar dados anteriores mantendo a estrutura
TRUNCATE TABLE weekly_consumption CASCADE;
TRUNCATE TABLE productivity_metrics CASCADE;
TRUNCATE TABLE irrigation_events CASCADE;
TRUNCATE TABLE sensor_readings CASCADE;
TRUNCATE TABLE alerts CASCADE;
TRUNCATE TABLE sectors CASCADE;
TRUNCATE TABLE automation_settings CASCADE;
TRUNCATE TABLE users CASCADE;

-- 1.1 Usuários Padrão (Senha: 123456)
INSERT INTO users (name, email, password_hash, role) VALUES
('Operador IrrigaTech', 'operador@irrigatech.com', '$2b$10$iCAmiKUfYuCnsZqcu9xeVO0wPMhAzVDHR4RNPI0H0e2ALNUiHZ2F2', 'operator'),
('Administrador', 'admin@irrigatech.com', '$2b$10$iCAmiKUfYuCnsZqcu9xeVO0wPMhAzVDHR4RNPI0H0e2ALNUiHZ2F2', 'admin');

-- 2. Configurações de Automação
INSERT INTO automation_settings (
    is_system_active, 
    operation_mode, 
    min_moisture_trigger, 
    max_moisture_cutoff, 
    next_irrigation_time, 
    next_irrigation_sectors, 
    daily_progress_pct
) VALUES (
    TRUE, 
    'Automático', 
    30.00, 
    75.00, 
    '14:30', 
    'Setores B e D (Milho & Algodão)', 
    65.00
);

-- 3. Setores Agrícolas
INSERT INTO sectors (id, name, region, crop, status, flow_rate, moisture, temperature, alert_message) VALUES
('setor_a', 'Setor A', 'Norte', 'Soja', 'irrigating', 45.00, 45.00, 28.00, NULL),
('setor_b', 'Setor B', 'Leste', 'Milho', 'idle', 0.00, 60.00, 26.50, NULL),
('setor_c', 'Setor C', 'Sul', 'Café Especial', 'error', 0.00, 18.00, 31.00, 'Vazamento Detectado na Linha Principal'),
('setor_d', 'Setor D', 'Oeste', 'Algodão', 'idle', 0.00, 52.00, 27.00, NULL),
('setor_e', 'Setor E', 'Central', 'Feijão Irrigado', 'idle', 0.00, 58.00, 26.00, NULL),
('setor_f', 'Setor F', 'Noroeste', 'Cana-de-Açúcar', 'irrigating', 55.00, 38.00, 29.50, NULL);

-- 4. Alertas do Sistema
INSERT INTO alerts (id, sector_id, title, description, severity, is_resolved, created_at) VALUES
('alert_1', 'setor_a', 'Umidade baixa no Setor A', 'Níveis abaixo de 15%. Irrigação de emergência recomendada para evitar estresse hídrico.', 'critical', FALSE, NOW() - INTERVAL '15 minutes'),
('alert_2', 'setor_c', 'Vazamento detectado no Setor C', 'Pressão anormal na linha principal detectada pelo sensor de fluxo há 25 min.', 'warning', FALSE, NOW() - INTERVAL '25 minutes'),
('alert_3', 'setor_f', 'Alta evapotranspiração no Setor F', 'Temperatura acima de 32°C com umidade relativa em 30%. Demanda hídrica elevada.', 'info', FALSE, NOW() - INTERVAL '1 hour'),
('alert_4', 'setor_b', 'Bateria baixa no sensor de solo B-02', 'Bateria atingiu 18%. Recomenda-se substituição preventiva.', 'warning', TRUE, NOW() - INTERVAL '2 days');

-- 5. Série Temporal de Leituras de Sensores (Últimas 24 horas - Setor A)
INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, recorded_at) VALUES
('setor_a', 32.0, 22.0, 0.0, NOW() - INTERVAL '24 hours'),
('setor_a', 33.5, 21.5, 0.0, NOW() - INTERVAL '21 hours'),
('setor_a', 35.0, 23.0, 0.0, NOW() - INTERVAL '18 hours'),
('setor_a', 38.0, 25.5, 0.0, NOW() - INTERVAL '15 hours'),
('setor_a', 42.0, 27.0, 0.0, NOW() - INTERVAL '12 hours'),
('setor_a', 50.0, 29.0, 0.0, NOW() - INTERVAL '9 hours'),
('setor_a', 55.0, 30.5, 0.0, NOW() - INTERVAL '6 hours'),
('setor_a', 48.0, 29.0, 1.5, NOW() - INTERVAL '3 hours'),
('setor_a', 45.0, 28.0, 2.0, NOW());

-- Leituras do Setor B (Milho)
INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, recorded_at) VALUES
('setor_b', 58.0, 22.5, 0.0, NOW() - INTERVAL '24 hours'),
('setor_b', 60.0, 24.0, 0.0, NOW() - INTERVAL '16 hours'),
('setor_b', 62.0, 26.5, 0.5, NOW() - INTERVAL '8 hours'),
('setor_b', 60.0, 26.5, 0.0, NOW());

-- Leituras do Setor C (Sul - Café)
INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, recorded_at) VALUES
('setor_c', 28.0, 25.0, 0.0, NOW() - INTERVAL '24 hours'),
('setor_c', 22.0, 28.0, 0.0, NOW() - INTERVAL '12 hours'),
('setor_c', 18.0, 31.0, 0.0, NOW());

-- 6. Histórico de Eventos de Irrigação
INSERT INTO irrigation_events (sector_id, start_time, end_time, duration_minutes, water_volume_m3, triggered_by) VALUES
('setor_a', NOW() - INTERVAL '2 days' - INTERVAL '4 hours', NOW() - INTERVAL '2 days', 240, 180.00, 'Automático'),
('setor_b', NOW() - INTERVAL '1 day' - INTERVAL '3 hours', NOW() - INTERVAL '1 day', 180, 135.00, 'Automático'),
('setor_d', NOW() - INTERVAL '18 hours', NOW() - INTERVAL '15 hours', 180, 120.00, 'Agendamento'),
('setor_e', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '10 hours', 120, 90.00, 'Manual'),
('setor_a', NOW() - INTERVAL '1 hour', NULL, 60, 45.00, 'Automático'),
('setor_f', NOW() - INTERVAL '30 minutes', NULL, 30, 27.50, 'Manual');

-- 7. Métricas de Produtividade (Sacas/ha - Comparativo de Safra)
INSERT INTO productivity_metrics (plot_label, current_cycle_yield, previous_cycle_yield, crop, year) VALUES
('Talhão A', 68.0, 60.0, 'Soja', 2026),
('Talhão B', 74.0, 64.0, 'Milho', 2026),
('Talhão C', 56.0, 52.0, 'Café', 2026),
('Talhão D', 78.0, 68.0, 'Algodão', 2026),
('Talhão E', 62.0, 55.0, 'Feijão', 2026);

-- 8. Comparativo Semanal de Consumo de Água
INSERT INTO weekly_consumption (sector_name, previous_week_m3, current_week_m3, variation_pct, is_decrease) VALUES
('Setor A', 120.00, 105.00, -12.50, TRUE),
('Setor B', 95.00, 102.00, 7.30, FALSE),
('Setor C', 150.00, 148.00, -1.30, TRUE),
('Setor D', 110.00, 98.00, -10.90, TRUE),
('Setor E', 85.00, 80.00, -5.80, TRUE),
('Setor F', 140.00, 132.00, -5.70, TRUE);

COMMIT;
