-- Migration 006: Histórico Mensal de Consumo Hídrico, Energia e Tarifas para Cálculo Real de Economia e ROI nos Relatórios

CREATE TABLE IF NOT EXISTS monthly_consumption_history (
    id SERIAL PRIMARY KEY,
    month_key VARCHAR(7) NOT NULL UNIQUE,
    month_label VARCHAR(20) NOT NULL,
    water_consumed_m3 NUMERIC(12,2) NOT NULL DEFAULT 0,
    energy_consumed_kwh NUMERIC(12,2) NOT NULL DEFAULT 0,
    water_tariff_brl NUMERIC(8,2) NOT NULL DEFAULT 3.85,
    energy_tariff_brl NUMERIC(8,2) NOT NULL DEFAULT 0.78,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insere histórico mensal base no banco de dados (caso ainda não exista) para comparação mês a mês:
-- Tarifas médias agrícolas: Água = R$ 3,85 / m³ | Energia = R$ 0,78 / kWh
INSERT INTO monthly_consumption_history (month_key, month_label, water_consumed_m3, energy_consumed_kwh, water_tariff_brl, energy_tariff_brl)
VALUES
    ('2026-04', 'Abr/26', 1850.00, 1620.00, 3.85, 0.78),
    ('2026-05', 'Mai/26', 1720.00, 1510.00, 3.85, 0.78),
    ('2026-06', 'Jun/26', 1610.00, 1420.00, 3.85, 0.78),
    ('2026-07', 'Jul/26', 1540.00, 1360.00, 3.85, 0.78),
    ('2026-08', 'Ago/26', 1490.00, 1290.00, 3.85, 0.78),
    ('2026-09', 'Set/26', 1420.00, 1240.00, 3.85, 0.78),
    ('2026-10', 'Out/26', 1120.00, 995.00, 3.85, 0.78)
ON CONFLICT (month_key) DO NOTHING;
