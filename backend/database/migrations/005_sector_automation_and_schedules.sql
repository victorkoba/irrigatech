-- Migration 005: Automação por Setor (Umidade Ideal, Gatilho, Corte, Ativo/Desativado) e Múltiplos Agendamentos

ALTER TABLE sectors ADD COLUMN IF NOT EXISTS is_enabled BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS ideal_moisture NUMERIC(5,2) NOT NULL DEFAULT 60.0;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS min_moisture_trigger NUMERIC(5,2) NOT NULL DEFAULT 35.0;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS max_moisture_cutoff NUMERIC(5,2) NOT NULL DEFAULT 75.0;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS last_activated_at TIMESTAMP;
ALTER TABLE sectors ADD COLUMN IF NOT EXISTS activation_reason VARCHAR(255);

-- Atualiza setores existentes que estão irrigando com motivo e data de ativação
UPDATE sectors
SET last_activated_at = COALESCE(last_activated_at, CURRENT_TIMESTAMP),
    activation_reason = COALESCE(activation_reason, 'Acionamento Automático: Umidade abaixo da ideal (45% < 60%)')
WHERE status = 'irrigating';

-- Tabela de Agendamentos de Irrigação (múltiplos agendamentos com opção de selecionar todos ou setores específicos, ativar/desativar, editar e excluir)
CREATE TABLE IF NOT EXISTS irrigation_schedules (
    id VARCHAR(64) PRIMARY KEY,
    scheduled_time VARCHAR(10) NOT NULL,
    sector_ids TEXT NOT NULL DEFAULT '["ALL"]',
    sectors_label VARCHAR(255) NOT NULL DEFAULT 'Todos os Setores',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO irrigation_schedules (id, scheduled_time, sector_ids, sectors_label, is_active)
SELECT 'sched_default_1', '14:30', '["setor_b","setor_d"]', 'Setor B, Setor D', true
WHERE NOT EXISTS (SELECT 1 FROM irrigation_schedules WHERE id = 'sched_default_1');

INSERT INTO irrigation_schedules (id, scheduled_time, sector_ids, sectors_label, is_active)
SELECT 'sched_default_2', '06:00', '["ALL"]', 'Todos os Setores', true
WHERE NOT EXISTS (SELECT 1 FROM irrigation_schedules WHERE id = 'sched_default_2');
