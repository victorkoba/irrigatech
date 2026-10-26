const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'irrigatech-dev-secret-troque-em-producao';
const JWT_EXPIRES_IN = '7d';

// Fallback em memória (usado quando o PostgreSQL está offline).
// Os usuários somem quando o servidor reinicia.
const memoryUsers = [];

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

async function findUserByEmail(email) {
  if (db.isDbConnected()) {
    const result = await db.query(
      'SELECT id, name, email, password_hash, role FROM users WHERE email = $1',
      [email]
    );
    return result.rows[0] || null;
  }
  return memoryUsers.find((u) => u.email === email) || null;
}

async function createUser(name, email, passwordHash) {
  if (db.isDbConnected()) {
    const result = await db.query(
      'INSERT INTO users (name, email, password_hash) VALUES ($1, $2, $3) RETURNING id, name, email, role',
      [name, email, passwordHash]
    );
    return result.rows[0];
  }
  const user = {
    id: memoryUsers.length + 1,
    name,
    email,
    password_hash: passwordHash,
    role: 'operator',
  };
  memoryUsers.push(user);
  return { id: user.id, name: user.name, email: user.email, role: user.role };
}

function publicUser(u) {
  return { id: u.id, name: u.name, email: u.email, role: u.role };
}

exports.register = async (req, res) => {
  const name = String(req.body.name || '').trim();
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Preencha nome, e-mail e senha.' });
  }
  if (!EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'E-mail inválido.' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'A senha precisa ter pelo menos 6 caracteres.' });
  }

  try {
    if (await findUserByEmail(email)) {
      return res.status(409).json({ error: 'Este e-mail já está cadastrado.' });
    }
    const passwordHash = await bcrypt.hash(password, 10);
    const user = await createUser(name, email, passwordHash);
    return res.status(201).json({ message: 'Conta criada com sucesso.', user });
  } catch (error) {
    console.error('Error registering user:', error);
    return res.status(500).json({ error: 'Erro ao criar conta.' });
  }
};

exports.login = async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');

  if (!email || !password) {
    return res.status(400).json({ error: 'Informe e-mail e senha.' });
  }

  try {
    const user = await findUserByEmail(email);
    const valid = user && (await bcrypt.compare(password, user.password_hash));
    if (!valid) {
      return res.status(401).json({ error: 'E-mail ou senha incorretos.' });
    }

    const token = jwt.sign(
      { sub: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    return res.json({ token, user: publicUser(user) });
  } catch (error) {
    console.error('Error logging in:', error);
    return res.status(500).json({ error: 'Erro ao entrar.' });
  }
};