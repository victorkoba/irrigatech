-- ==========================================================
-- Migration 004: Janelas de Tempo do Monitoramento
-- (Umidade e Energia de 1 em 1 hora; Temperatura e Precipitação de 10 em 10 min)
-- ==========================================================

CREATE TABLE IF NOT EXISTS sector_monitoring_snapshots (
    sector_id VARCHAR(50) PRIMARY KEY REFERENCES sectors(id) ON DELETE CASCADE,
    avg_moisture_1h NUMERIC(5, 2),
    avg_energy_1h NUMERIC(8, 2),
    hourly_samples_count INT DEFAULT 0,
    hourly_calculated_at TIMESTAMP WITH TIME ZONE,
    hourly_next_update_at TIMESTAMP WITH TIME ZONE,
    avg_temperature_10m NUMERIC(5, 2),
    avg_precipitation_10m NUMERIC(5, 2),
    ten_min_samples_count INT DEFAULT 0,
    ten_min_calculated_at TIMESTAMP WITH TIME ZONE,
    ten_min_next_update_at TIMESTAMP WITH TIME ZONE
);

INSERT INTO system_features (id, module, title, description, is_active) VALUES
('feat_monitoramento_janelas', 'Monitoramento', 'Janelas de Agregação (1h e 10min) e Consumo de Energia', 'Umidade do solo e Consumo de Energia calculam a média de 1 em 1 hora; Temperatura e Precipitação calculam a média de 10 em 10 minutos a partir dos dados gerados pelo script Python no banco.', TRUE),
('feat_historico_diario_relatorio', 'Monitoramento', 'Histórico Horário em Colunas e Histórico Completo do Dia', 'Exibe gráfico de colunas de 1 em 1 hora com botão para abrir todo o histórico do dia e opção de baixar o relatório CSV.', TRUE)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();
