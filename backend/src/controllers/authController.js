const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'irrigatech-dev-secret-troque-em-producao';
const JWT_EXPIRES_IN = '7d';
const MASTER_ADMIN_EMAIL = 'victor@gmail.com';

// Fallback em memória (usado quando o PostgreSQL está offline).
// Os usuários somem quando o servidor reinicia.
const memoryUsers = [
  {
    id: 1,
    name: 'Victor Koba',
    email: MASTER_ADMIN_EMAIL,
    password_hash: '$2b$10$iCAmiKUfYuCnsZqcu9xeVO0wPMhAzVDHR4RNPI0H0e2ALNUiHZ2F2',
    role: 'ADMIN',
    created_at: new Date().toISOString(),
  },
  {
    id: 2,
    name: 'Operador IrrigaTech',
    email: 'operador@irrigatech.com',
    password_hash: '$2b$10$iCAmiKUfYuCnsZqcu9xeVO0wPMhAzVDHR4RNPI0H0e2ALNUiHZ2F2',
    role: 'Operador',
    created_at: new Date().toISOString(),
  },
];

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function resolveRoleByEmail(email) {
  return String(email || '').trim().toLowerCase() === MASTER_ADMIN_EMAIL
    ? 'ADMIN'
    : 'Operador';
}

async function findUserByEmail(email) {
  const normalizedEmail = String(email || '').trim().toLowerCase();
  if (db.isDbConnected()) {
    const result = await db.query(
      'SELECT id, name, email, password_hash, role, created_at FROM users WHERE LOWER(email) = LOWER($1)',
      [normalizedEmail]
    );
    const user = result.rows[0] || null;
    if (user) {
      const expectedRole = resolveRoleByEmail(user.email);
      if (user.role !== expectedRole) {
        await db.query('UPDATE users SET role = $1 WHERE id = $2', [expectedRole, user.id]);
        user.role = expectedRole;
      }
    }
    return user;
  }
  return memoryUsers.find((u) => u.email.toLowerCase() === normalizedEmail) || null;
}

async function createUser(name, email, passwordHash) {
  const normalizedEmail = String(email || '').trim().toLowerCase();
  const role = resolveRoleByEmail(normalizedEmail);

  if (db.isDbConnected()) {
    const result = await db.query(
      'INSERT INTO users (name, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING id, name, email, role, created_at',
      [name, normalizedEmail, passwordHash, role]
    );
    return result.rows[0];
  }
  const user = {
    id: memoryUsers.length + 1,
    name,
    email: normalizedEmail,
    password_hash: passwordHash,
    role,
    created_at: new Date().toISOString(),
  };
  memoryUsers.push(user);
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    role: user.role,
    created_at: user.created_at,
  };
}

function publicUser(u) {
  return {
    id: u.id,
    name: u.name,
    email: u.email,
    role: resolveRoleByEmail(u.email),
    created_at: u.created_at,
  };
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
    return res.status(201).json({ message: 'Usuário cadastrado com sucesso.', user: publicUser(user) });
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

    const normalizedUser = publicUser(user);
    const token = jwt.sign(
      { sub: normalizedUser.id, email: normalizedUser.email, role: normalizedUser.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );
    return res.json({ token, user: normalizedUser });
  } catch (error) {
    console.error('Error logging in:', error);
    return res.status(500).json({ error: 'Erro ao entrar.' });
  }
};

exports.getUsers = async (req, res) => {
  try {
    if (db.isDbConnected()) {
      const result = await db.query(
        `SELECT id, name, email, role, created_at
         FROM users
         ORDER BY CASE WHEN role = 'ADMIN' THEN 0 ELSE 1 END, id ASC`
      );
      return res.json({
        users: result.rows.map(publicUser),
      });
    }
    return res.json({
      users: memoryUsers.map(publicUser),
    });
  } catch (error) {
    console.error('Error fetching users:', error);
    return res.status(500).json({ error: 'Erro ao listar usuários.' });
  }
};
