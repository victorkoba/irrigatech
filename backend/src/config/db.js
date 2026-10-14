const { Pool } = require('pg');
require('dotenv').config();

let isConnected = false;

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'postgrespassword',
  database: process.env.DB_NAME || 'irrigatech',
  connectionTimeoutMillis: 2000,
});

async function checkDatabaseConnection() {
  try {
    const client = await pool.connect();
    isConnected = true;
    console.log('✅ [Database] Conexão com PostgreSQL estabelecida com sucesso!');
    client.release();
  } catch (err) {
    isConnected = false;
    console.log('⚠️ [Database] PostgreSQL offline no momento. O backend está operando em modo de memória seguro.');
    console.log('👉 [DBeaver / Docker]: Inicie o banco com `docker compose up -d` ou conecte via DBeaver na porta 5432.');
  }
}

// Check initial connection
checkDatabaseConnection();

module.exports = {
  pool,
  isDbConnected: () => isConnected,
  query: (text, params) => pool.query(text, params),
};
