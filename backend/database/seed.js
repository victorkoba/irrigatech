const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgrespassword',
  database: process.env.DB_NAME || 'irrigatech',
});

async function runSeed() {
  console.log('\n======================================================');
  console.log('🌱 [IrrigaTech] Iniciando Seeder do Banco de Dados...');
  console.log('======================================================\n');
  console.log(`🔌 Conectando ao PostgreSQL em ${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || '5432'}...`);

  let client;
  try {
    client = await pool.connect();
    console.log('✅ Conectado com sucesso ao banco:', process.env.DB_NAME || 'irrigatech');

    // 1. Check if schema exists, if not execute schema.sql first
    const checkTable = await client.query(`
      SELECT to_regclass('public.sectors') AS exists;
    `);

    if (!checkTable.rows[0].exists) {
      console.log('📄 Tabelas não encontradas. Criando estrutura a partir de schema.sql...');
      const schemaSql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf-8');
      await client.query(schemaSql);
      console.log('✅ Estrutura de tabelas criada com sucesso!');
    }

    // 2. Read and execute seeder.sql
    console.log('🌾 Executando inserções de dados do seeder.sql...');
    const seederSql = fs.readFileSync(path.join(__dirname, 'seeder.sql'), 'utf-8');
    await client.query(seederSql);

    // 3. Count rows in each table to give feedback
    const tables = [
      'users',
      'sectors',
      'sensor_readings',
      'alerts',
      'automation_settings',
      'irrigation_events',
      'productivity_metrics',
      'weekly_consumption',
    ];

    console.log('\n📊 Resumo dos dados inseridos no banco:');
    for (const t of tables) {
      const res = await client.query(`SELECT COUNT(*) FROM ${t}`);
      console.log(`   - Tabela '${t}': ${res.rows[0].count} registro(s)`);
    }

    console.log('\n🎉 [Sucesso] Banco de dados populado com sucesso!');
    console.log('👉 Abra o DBeaver para explorar os novos registros.');
    console.log('======================================================\n');
  } catch (error) {
    console.error('\n❌ Erro ao popular banco de dados:');
    if (error.code === 'ECONNREFUSED') {
      console.error('⚠️  Não foi possível conectar ao PostgreSQL na porta 5432.');
      console.error('👉 Verifique se o container está rodando com `docker compose up -d` no Docker Desktop.');
    } else {
      console.error(error.message);
    }
    process.exit(1);
  } finally {
    if (client) client.release();
    await pool.end();
  }
}

runSeed();
