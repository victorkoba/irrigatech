-- ==========================================================
-- Migration 003: Organização do Sistema, Metadados no Banco,
-- Alertas Condicionais por Limite (Água, Energia, Temperatura)
-- e Snapshot Horário (1 em 1 hora, estático por 59 min) na Dashboard
-- ==========================================================

-- 1. Metadados e Descrições Oficiais do Projeto no Banco de Dados
CREATE TABLE IF NOT EXISTS system_metadata (
    id SERIAL PRIMARY KEY,
    summary_description TEXT NOT NULL,
    expected_benefits TEXT NOT NULL,
    detailed_description TEXT NOT NULL,
    status_card_description TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_metadata (id, summary_description, expected_benefits, detailed_description, status_card_description)
VALUES (
    1,
    'Clientes corporativos no segmento agrícola enfrentam dificuldades em controlar o uso eficiente da água e energia, pois o manejo é feito com base em monitoramento manual. Isso ocasiona desperdício de água, custos crescentes de energia elétrica, baixa precisão na irrigação que compromete a produtividade e dificuldade em mensurar resultados com base em dados concretos.',
    'Monitoramento da umidade do solo e variáveis climáticas em tempo real; Acionamento inteligente e automático; Geração de relatórios automáticos de economia de água, energia e produtividade; Controle remoto via aplicativo mobile, dispensando deslocamentos até o campo; Garantia de conformidade ambiental, facilitando certificações e acesso a linhas de crédito rural sustentáveis.',
    'Empresas agrícolas com sistemas de irrigação manuais enfrentam altos custos operacionais e desperdício de recursos naturais por falta de automação e monitoramento inteligente. Elas precisam de uma solução acessível e integrada que otimize o uso de água e energia, aumente a produtividade e garanta conformidade ambiental. Os equipamentos existentes atualmente precisam ser importados o que aumenta os recursos para investimento.',
    'Estado em que o controle de irrigação está definido pelo cliente.'
)
ON CONFLICT (id) DO UPDATE SET
    summary_description = EXCLUDED.summary_description,
    expected_benefits = EXCLUDED.expected_benefits,
    detailed_description = EXCLUDED.detailed_description,
    status_card_description = EXCLUDED.status_card_description,
    updated_at = NOW();

-- 2. Catálogo de Funcionalidades e Descrições Persistido no Banco de Dados
CREATE TABLE IF NOT EXISTS system_features (
    id VARCHAR(50) PRIMARY KEY,
    module VARCHAR(50) NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_features (id, module, title, description, is_active) VALUES
('feat_status_geral', 'Dashboard', 'Status Geral do Sistema', 'Exibe se o sistema está Ativo ou Suspenso, representando o estado em que o controle de irrigação foi definido pelo cliente.', TRUE),
('feat_alertas_condicionais', 'Dashboard', 'Alertas de Consumo e Temperatura', 'Exibe alertas na Dashboard exclusivamente quando algum setor monitorado apresentar valores muito altos de consumo de água, energia elétrica e/ou temperatura.', TRUE),
('feat_proxima_irrigacao', 'Dashboard / Controle', 'Próxima Irrigação Agendada', 'Resgata do banco de dados o próximo horário e setores programados para irrigação, configurados na aba de Controle.', TRUE),
('feat_cards_media_horaria', 'Dashboard / Monitoramento', 'Cards de Média Consolidada (1 em 1 hora)', 'Resgata do banco de dados as leituras geradas pelo monitoramento (script Python) a cada 1 hora, calcula a média do período e mantém os indicadores estáticos durante os 59 minutos seguintes.', TRUE),
('feat_monitoramento_tempo_real', 'Monitoramento', 'Telemetria de Setores em Tempo Real', 'Recebe leituras contínuas de água, energia, temperatura e umidade via script Python, exibindo apenas os setores cadastrados na aba de Controle.', TRUE),
('feat_controle_setores', 'Controle', 'Gerenciamento e Parada de Emergência com Snapshot', 'Permite cadastrar setores, alternar entre modo Automático e Manual, e acionar Desligar Tudo salvando o estado dos setores ativos para restaurá-los ao Reativar Sistema.', TRUE)
ON CONFLICT (id) DO UPDATE SET
    module = EXCLUDED.module,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    updated_at = NOW();

-- 3. Novas Colunas em Sectors para Monitoramento de Energia e Limites de Alerta
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS energy_consumption NUMERIC(8, 2) NOT NULL DEFAULT 35.00;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS water_alert_threshold NUMERIC(8, 2) NOT NULL DEFAULT 80.00;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS energy_alert_threshold NUMERIC(8, 2) NOT NULL DEFAULT 100.00;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS temperature_alert_threshold NUMERIC(5, 2) NOT NULL DEFAULT 35.00;

-- Normaliza setores iniciais para valores dentro da faixa normal (sem alertas falsos iniciais)
UPDATE sectors SET flow_rate = 45.00, energy_consumption = 42.00, temperature = 28.00 WHERE id = 'setor_a';
UPDATE sectors SET flow_rate = 0.00, energy_consumption = 0.00, temperature = 26.50, status = 'idle', alert_message = NULL WHERE id = 'setor_b';
UPDATE sectors SET flow_rate = 0.00, energy_consumption = 0.00, temperature = 31.00 WHERE id = 'setor_c';
UPDATE sectors SET flow_rate = 0.00, energy_consumption = 0.00, temperature = 27.00 WHERE id = 'setor_d';

-- 4. Novas Colunas em Sensor Readings para Água, Energia e Eficiência (alimentadas pelo script Python)
ALTER TABLE sensor_readings ADD COLUMN IF NOT EXISTS water_consumption NUMERIC(8, 2) NOT NULL DEFAULT 45.00;
ALTER TABLE sensor_readings ADD COLUMN IF NOT EXISTS energy_consumption NUMERIC(8, 2) NOT NULL DEFAULT 42.00;
ALTER TABLE sensor_readings ADD COLUMN IF NOT EXISTS efficiency NUMERIC(5, 2) NOT NULL DEFAULT 94.00;

-- 5. Colunas adicionais em Alerts para rastrear a origem do alerta (água, energia, temperatura)
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS metric_type VARCHAR(30) DEFAULT 'threshold';
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS water_value NUMERIC(8, 2);
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS energy_value NUMERIC(8, 2);
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS temperature_value NUMERIC(5, 2);

-- Remove alertas estáticos antigos que não vieram da condição de alto consumo de água/energia/temperatura
DELETE FROM alerts WHERE id IN ('alert_1', 'alert_2');

-- 6. Tabela de Snapshot Horário da Dashboard (atualiza de 1 em 1 hora e fica estático por 59 minutos)
CREATE TABLE IF NOT EXISTS dashboard_hourly_snapshots (
    id SERIAL PRIMARY KEY,
    avg_water_consumption NUMERIC(8, 2) NOT NULL DEFAULT 45.00,
    avg_energy_consumption NUMERIC(8, 2) NOT NULL DEFAULT 42.00,
    avg_temperature NUMERIC(5, 2) NOT NULL DEFAULT 27.50,
    avg_moisture NUMERIC(5, 2) NOT NULL DEFAULT 48.00,
    avg_efficiency NUMERIC(5, 2) NOT NULL DEFAULT 94.00,
    water_trend VARCHAR(80) DEFAULT 'Média consolidada (última 1h)',
    energy_trend VARCHAR(80) DEFAULT 'Média consolidada (última 1h)',
    efficiency_trend VARCHAR(80) DEFAULT 'Ciclo de 60 min (estático por 59 min)',
    samples_count INT NOT NULL DEFAULT 1,
    window_start TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() - INTERVAL '1 hour'),
    window_end TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    calculated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    next_update_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT (NOW() + INTERVAL '1 hour')
);

-- Insere leituras recentes de exemplo na última 1 hora caso não existam
INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, water_consumption, energy_consumption, efficiency, recorded_at)
SELECT 'setor_a', 45.0, 28.0, 0.0, 45.0, 42.0, 94.0, NOW() - INTERVAL '30 minutes'
WHERE NOT EXISTS (SELECT 1 FROM sensor_readings WHERE recorded_at >= NOW() - INTERVAL '1 hour');

INSERT INTO sensor_readings (sector_id, moisture, temperature, precipitation, water_consumption, energy_consumption, efficiency, recorded_at)
SELECT 'setor_a', 46.0, 27.5, 0.0, 48.0, 44.0, 95.0, NOW() - INTERVAL '15 minutes'
WHERE NOT EXISTS (SELECT 1 FROM sensor_readings WHERE recorded_at >= NOW() - INTERVAL '20 minutes');
