const { test, describe, before, after } = require('node:test');
const assert = require('node:assert/strict');
const app = require('../src/server');

let server;
let baseUrl;

before(async () => {
  await new Promise((resolve) => {
    server = app.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://localhost:${port}/api`;
      resolve();
    });
  });
});

after(async () => {
  await new Promise((resolve) => {
    server.close(resolve);
  });
});

describe('1. Health Check & Diagnóstico do Sistema', () => {
  test('GET /health deve responder com status online e informações do banco', async () => {
    const res = await fetch(`${baseUrl}/health`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.status, 'online');
    assert.strictEqual(body.appName, 'IrrigaTech Backend API');
    assert.ok(body.database);
    assert.strictEqual(body.database.type, 'PostgreSQL');
    assert.ok('connected' in body.database);
  });
});

describe('2. Autenticação, Cadastro e Validações', () => {
  test('POST /auth/register - Rejeita campos obrigatórios vazios com 400', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: '', email: '', password: '' }),
    });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /Preencha nome/i);
  });

  test('POST /auth/register - Rejeita e-mail inválido com 400', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Teste', email: 'email-invalido', password: 'senha' }),
    });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /inválido/i);
  });

  test('POST /auth/register - Rejeita senha curta (< 6 caracteres) com 400', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Teste', email: 'teste@irriga.com', password: '123' }),
    });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /6 caracteres/i);
  });

  test('POST /auth/register - Cadastra novo usuário com sucesso (201)', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Victor Koba Test',
        email: 'victor.test@irrigatech.com',
        password: 'senhaSegura123',
      }),
    });
    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.strictEqual(body.user.email, 'victor.test@irrigatech.com');
    assert.strictEqual(body.user.name, 'Victor Koba Test');
  });

  test('POST /auth/register - Rejeita e-mail duplicado com 409', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Victor Outro',
        email: 'victor.test@irrigatech.com',
        password: 'senhaSegura123',
      }),
    });
    assert.strictEqual(res.status, 409);
    const body = await res.json();
    assert.match(body.error, /já está cadastrado/i);
  });

  test('POST /auth/login - Autentica usuário existente e retorna JWT token (200)', async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'victor.test@irrigatech.com',
        password: 'senhaSegura123',
      }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok(body.token, 'Token JWT deve ser retornado');
    assert.strictEqual(body.user.email, 'victor.test@irrigatech.com');
  });

  test('POST /auth/login - Rejeita senha incorreta com 401', async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'victor.test@irrigatech.com',
        password: 'senhaErrada',
      }),
    });
    assert.strictEqual(res.status, 401);
  });

  test('POST /auth/login - Rejeita usuário inexistente com 401', async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'inexistente@irrigatech.com',
        password: 'qualquercoisa',
      }),
    });
    assert.strictEqual(res.status, 401);
  });
});

describe('3. Dashboard e Monitoramento Geral', () => {
  test('GET /dashboard/summary - Retorna status, KPIs e alertas', async () => {
    const res = await fetch(`${baseUrl}/dashboard/summary`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok('isSystemActive' in body);
    assert.ok(body.nextIrrigation);
    assert.ok(body.kpis.waterConsumption);
    assert.ok(body.kpis.energyConsumption);
    assert.ok(body.kpis.efficiency);
    assert.ok(Array.isArray(body.criticalAlerts));
  });
});

describe('4. Gestão e Controle de Setores de Irrigação', () => {
  test('GET /sectors - Lista todos os setores com telemetria', async () => {
    const res = await fetch(`${baseUrl}/sectors`);
    assert.strictEqual(res.status, 200);
    const sectors = await res.json();
    assert.ok(Array.isArray(sectors));
    assert.ok(sectors.length >= 3);
    const sectorA = sectors.find((s) => s.id === 'setor_a');
    assert.ok(sectorA);
    assert.ok('flowRate' in sectorA);
    assert.ok('moisture' in sectorA);
  });

  test('POST /sectors/:id/toggle - Alterna status de irrigação do setor', async () => {
    // Alterna Setor B (inicialmente idle -> irrigating)
    const toggleRes = await fetch(`${baseUrl}/sectors/setor_b/toggle`, { method: 'POST' });
    assert.strictEqual(toggleRes.status, 200);
    const toggled = await toggleRes.json();
    assert.strictEqual(toggled.id, 'setor_b');
    assert.strictEqual(toggled.status, 'irrigating');
    assert.ok(toggled.flowRate > 0);

    // Alterna novamente (irrigating -> idle)
    const toggleBackRes = await fetch(`${baseUrl}/sectors/setor_b/toggle`, { method: 'POST' });
    assert.strictEqual(toggleBackRes.status, 200);
    const back = await toggleBackRes.json();
    assert.strictEqual(back.status, 'idle');
    assert.strictEqual(back.flowRate, 0);
  });

  test('POST /sectors/:id/toggle - Bloqueia acionamento de setor em estado de erro (400)', async () => {
    const res = await fetch(`${baseUrl}/sectors/setor_c/toggle`, { method: 'POST' });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /erro/i);
  });

  test('PUT /sectors/:id/flow-rate - Atualiza a vazão hídrica', async () => {
    const res = await fetch(`${baseUrl}/sectors/setor_a/flow-rate`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ flowRate: 52.5 }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.id, 'setor_a');
    assert.strictEqual(body.flowRate, 52.5);
  });
});

describe('5. Automação e Protocolos de Segurança', () => {
  test('POST /irrigation/emergency-stop - Aciona parada total de emergência', async () => {
    const res = await fetch(`${baseUrl}/irrigation/emergency-stop`, { method: 'POST' });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.isSystemActive, false);

    // Valida se os setores foram desligados
    const sectorsRes = await fetch(`${baseUrl}/sectors`);
    const sectors = await sectorsRes.json();
    const irrigating = sectors.filter((s) => s.status === 'irrigating');
    assert.strictEqual(irrigating.length, 0);
  });

  test('POST /irrigation/resume - Reativa operação do sistema', async () => {
    const res = await fetch(`${baseUrl}/irrigation/resume`, { method: 'POST' });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.isSystemActive, true);
  });

  test('PUT /irrigation/mode - Valida e atualiza modo de operação', async () => {
    // Modo válido
    const validRes = await fetch(`${baseUrl}/irrigation/mode`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mode: 'Manual' }),
    });
    assert.strictEqual(validRes.status, 200);
    const validBody = await validRes.json();
    assert.strictEqual(validBody.operationMode, 'Manual');

    // Modo inválido (deve rejeitar com 400)
    const invalidRes = await fetch(`${baseUrl}/irrigation/mode`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ mode: 'InvalidoModo' }),
    });
    assert.strictEqual(invalidRes.status, 400);
  });

  test('PUT /irrigation/parameters - Atualiza limites de umidade', async () => {
    const res = await fetch(`${baseUrl}/irrigation/parameters`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ minMoisture: 35.0, maxMoisture: 80.0 }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.minMoistureTrigger, 35.0);
    assert.strictEqual(body.maxMoistureCutoff, 80.0);
  });
});

describe('6. Telemetria e Monitoramento de Sensores IoT', () => {
  test('GET /monitoring/readings/:sectorId - Histórico de leituras', async () => {
    const res = await fetch(`${baseUrl}/monitoring/readings/setor_a`);
    assert.strictEqual(res.status, 200);
    const readings = await res.json();
    assert.ok(Array.isArray(readings));
    assert.ok(readings.length > 0);
    assert.ok('moisture' in readings[0]);
  });

  test('GET /monitoring/weekly-comparison - Comparativo de consumo semanal', async () => {
    const res = await fetch(`${baseUrl}/monitoring/weekly-comparison`);
    assert.strictEqual(res.status, 200);
    const weekly = await res.json();
    assert.ok(Array.isArray(weekly));
    assert.ok(weekly.length > 0);
    assert.ok('previousWeek' in weekly[0]);
    assert.ok('currentWeek' in weekly[0]);
    assert.ok('variation' in weekly[0]);
  });

  test('POST /monitoring/readings - Ingestão de leitura IoT', async () => {
    const res = await fetch(`${baseUrl}/monitoring/readings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sectorId: 'setor_a',
        moisture: 47.5,
        temperature: 27.2,
        precipitation: 0.5,
      }),
    });
    assert.strictEqual(res.status, 201);
  });
});

describe('7. Relatórios e Exportação', () => {
  test('GET /reports/overview - Resumo de economia, produtividade e conformidade', async () => {
    const res = await fetch(`${baseUrl}/reports/overview`);
    assert.strictEqual(res.status, 200);
    const overview = await res.json();
    assert.ok(overview.summary);
    assert.ok(overview.productivity);
    assert.ok(overview.compliance);
    assert.ok(Array.isArray(overview.exportableReports));
  });

  test('GET /reports/export/:id - Download de relatório CSV', async () => {
    const res = await fetch(`${baseUrl}/reports/export/water_report`);
    assert.strictEqual(res.status, 200);
    const contentType = res.headers.get('content-type');
    assert.ok(contentType.includes('text/csv'));
    const text = await res.text();
    assert.match(text, /Setor/);
  });

  test('GET /reports/export/:id - Relatório inexistente retorna 404', async () => {
    const res = await fetch(`${baseUrl}/reports/export/id_invalido`);
    assert.strictEqual(res.status, 404);
  });
});

describe('8. Tratamento de Erros e 404', () => {
  test('GET /rota-inexistente - Retorna 404 com mensagem padronizada', async () => {
    const res = await fetch(`${baseUrl}/rota-inexistente`);
    assert.strictEqual(res.status, 404);
    const body = await res.json();
    assert.strictEqual(body.error, 'Endpoint não encontrado');
  });
});
