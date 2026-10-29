-- ==========================================================
-- Migration 007: Separação de Permissões de Usuários (ADMIN único e Operador)
-- Define victor@gmail.com como único ADMIN (MASTER) e demais como Operador
-- ==========================================================

-- 1. Limpar usuários temporários gerados por execuções anteriores de testes automatizados
DELETE FROM users WHERE email LIKE 'victor.test.%@irrigatech.com';

-- 2. Garantir que o usuário MASTER (victor@gmail.com) exista e tenha permissão ADMIN
INSERT INTO users (name, email, password_hash, role)
VALUES (
    'Victor Koba',
    'victor@gmail.com',
    '$2b$10$iCAmiKUfYuCnsZqcu9xeVO0wPMhAzVDHR4RNPI0H0e2ALNUiHZ2F2',
    'ADMIN'
)
ON CONFLICT (email) DO UPDATE
SET role = 'ADMIN';

-- 3. Garantir que todos os demais usuários tenham permissão 'Operador' (apenas 1 ADMIN no sistema)
UPDATE users
SET role = 'Operador'
WHERE LOWER(email) <> 'victor@gmail.com';

-- 4. Padronizar o valor default da coluna role para 'Operador'
ALTER TABLE users ALTER COLUMN role SET DEFAULT 'Operador';

-- 5. Garantir via constraint que apenas as permissões 'ADMIN' e 'Operador' existam no banco
ALTER TABLE users DROP CONSTRAINT IF EXISTS chk_users_role_valid;
ALTER TABLE users ADD CONSTRAINT chk_users_role_valid CHECK (role IN ('ADMIN', 'Operador'));

-- 6. Garantir no banco de dados que exista no máximo 1 usuário com role = 'ADMIN'
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_single_master_admin
ON users (role)
WHERE role = 'ADMIN';

-- 7. Documentar funcionalidade no catálogo do sistema (system_features)
INSERT INTO system_features (id, module, title, description, is_active)
VALUES (
    'profile_master_user_management',
    'Perfil',
    'Controle de Permissões (ADMIN Master e Operador) e Cadastro de Usuários',
    'Separação de usuários no banco de dados entre ADMIN (exclusivo para victor@gmail.com) e Operador. Remoção do auto-cadastro público na tela de login e adição do gerenciamento e cadastro de novos operadores (nome, e-mail e senha) na tela de Perfil pelo usuário ADMIN.',
    TRUE
)
ON CONFLICT (id) DO UPDATE
SET title = EXCLUDED.title,
    description = EXCLUDED.description,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;
