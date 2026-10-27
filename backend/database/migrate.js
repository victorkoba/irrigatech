const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const poolConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgrespassword',
  database: process.env.DB_NAME || 'irrigatech',
  connectionTimeoutMillis: 3000,
};

async function runMigrations(customPool = null) {
  const pool = customPool || new Pool(poolConfig);
  let client;

  try {
    client = await pool.connect();

    // 1. Garantir que a tabela de controle de migrations exista
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        executed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // 2. Ler todos os arquivos SQL no diretório migrations
    const migrationsDir = path.join(__dirname, 'migrations');
    if (!fs.existsSync(migrationsDir)) {
      console.log('Nenhum diretório de migrations encontrado.');
      return;
    }

    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    let appliedCount = 0;

    for (const file of files) {
      const check = await client.query(
        'SELECT id FROM schema_migrations WHERE name = $1',
        [file]
      );

      if (check.rows.length === 0) {
        console.log(`[Migration] Executando migration: ${file}...`);
        const filePath = path.join(migrationsDir, file);
        const sql = fs.readFileSync(filePath, 'utf-8');

        await client.query('BEGIN');
        try {
          await client.query(sql);
          await client.query(
            'INSERT INTO schema_migrations (name) VALUES ($1)',
            [file]
          );
          await client.query('COMMIT');
          console.log(`[Migration] Concluída com sucesso: ${file}`);
          appliedCount++;
        } catch (err) {
          await client.query('ROLLBACK');
          console.error(`[Migration] Falha ao executar ${file}:`, err.message);
          throw err;
        }
      }
    }

    if (appliedCount === 0) {
      console.log('[Migration] Banco de dados já está atualizado (nenhuma migration pendente).');
    } else {
      console.log(`[Migration] Total de ${appliedCount} migration(s) executada(s) com sucesso.`);
    }

    return true;
  } catch (error) {
    console.error('[Migration] Erro no processo de migração:', error.message);
    throw error;
  } finally {
    if (client) client.release();
    if (!customPool) await pool.end();
  }
}

if (require.main === module) {
  runMigrations()
    .then(() => {
      console.log('[Migration] Processo finalizado.');
      process.exit(0);
    })
    .catch((err) => {
      console.error('[Migration] Processo abortado com erro.', err);
      process.exit(1);
    });
}

module.exports = { runMigrations };
