-- ==========================================================
-- Migration 002: Carga Inicial de Dados (Seed Idempotente)
-- Insere dados básicos sem gerar duplicidade
-- ==========================================================

-- 1. Usuário Operador Padrão (operador@irrigatech.com / 123456)
INSERT INTO users (name, email, password_hash, role)
VALUES (
    'Operador Padrão',
    'operador@irrigatech.com',
    '$2b$10$fvMP.RCb0npcCKg5S5oyxO6Ro9yrkjtt/SU.peNoLoaS8NXvWj8PC',
    'operator'
)
ON CONFLICT (email) DO NOTHING;

-- 2. Configuração de Automação Padrão
INSERT INTO automation_settings (id, is_system_active, operation_mode, min_moisture_trigger, max_moisture_cutoff, next_irrigation_time, next_irrigation_sectors, daily_progress_pct)
VALUES (
    1,
    TRUE,
    'Automático',
    30.00,
    75.00,
    '14:30',
    'Setores B e D (Milho)',
    65.00
)
ON CONFLICT (id) DO NOTHING;

-- 3. Setores Agrícolas
INSERT INTO sectors (id, name, region, crop, status, flow_rate, moisture, temperature, alert_message)
VALUES 
    ('setor_a', 'Setor A', 'Norte', 'Milho', 'idle', 0.00, 45.00, 28.00, NULL),
    ('setor_b', 'Setor B', 'Sul', 'Soja', 'irrigating', 85.50, 28.00, 31.00, 'Umidade do solo crítica (28%)'),
    ('setor_c', 'Setor C', 'Leste', 'Café', 'error', 0.00, 52.00, 26.00, 'Pressão hidráulica abaixo do nominal (1.8 bar)'),
    ('setor_d', 'Setor D', 'Oeste', 'Milho', 'idle', 0.00, 68.00, 27.00, NULL)
ON CONFLICT (id) DO NOTHING;

-- 4. Alertas Iniciais
INSERT INTO alerts (id, sector_id, title, description, severity, is_resolved)
VALUES
    ('alert_1', 'setor_b', 'Nível crítico de umidade', 'Setor B atingiu 28% de umidade. Irrigação emergencial iniciada.', 'critical', FALSE),
    ('alert_2', 'setor_c', 'Falha na bomba secundária', 'Queda de pressão no setor C (1.8 bar). Verifique a linha de recalque.', 'warning', FALSE)
ON CONFLICT (id) DO NOTHING;

-- 5. Métricas de Produtividade
INSERT INTO productivity_metrics (plot_label, current_cycle_yield, previous_cycle_yield, crop, year)
VALUES
    ('Talhão A', 68.00, 60.00, 'Milho', 2026),
    ('Talhão B', 74.00, 64.00, 'Milho', 2026),
    ('Talhão C', 56.00, 52.00, 'Café', 2026),
    ('Talhão D', 78.00, 68.00, 'Soja', 2026)
ON CONFLICT DO NOTHING;

-- 6. Consumo Semanal
INSERT INTO weekly_consumption (sector_name, previous_week_m3, current_week_m3, variation_pct, is_decrease)
VALUES
    ('Setor A', 120.00, 105.00, -12.50, TRUE),
    ('Setor B', 95.00, 102.00, 7.30, FALSE),
    ('Setor C', 150.00, 148.00, -1.30, TRUE)
ON CONFLICT DO NOTHING;
