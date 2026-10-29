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
  const db = require('../src/config/db');
  if (db.isDbConnected()) {
    await db.query("DELETE FROM users WHERE email LIKE 'victor.test.%@irrigatech.com'");
  }
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
  const dynamicEmail = `victor.test.${Date.now()}@irrigatech.com`;
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
        email: dynamicEmail,
        password: 'senhaSegura123',
      }),
    });
    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.strictEqual(body.user.email, dynamicEmail);
    assert.strictEqual(body.user.name, 'Victor Koba Test');
  });

  test('POST /auth/register - Rejeita e-mail duplicado com 409', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Victor Outro',
        email: dynamicEmail,
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
        email: dynamicEmail,
        password: 'senhaSegura123',
      }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok(body.token, 'Token JWT deve ser retornado');
    assert.strictEqual(body.user.email, dynamicEmail);
  });

  test('POST /auth/login - Rejeita senha incorreta com 401', async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: dynamicEmail,
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

  test('GET /auth/users - Separa usuários por permissões (apenas victor@gmail.com como ADMIN e demais como Operador)', async () => {
    const res = await fetch(`${baseUrl}/auth/users`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok(Array.isArray(body.users));

    const admins = body.users.filter((u) => u.role === 'ADMIN');
    assert.strictEqual(admins.length, 1, 'Deve existir exatamente 1 usuário ADMIN no banco');
    assert.strictEqual(admins[0].email, 'victor@gmail.com');

    const operators = body.users.filter((u) => u.email !== 'victor@gmail.com');
    for (const op of operators) {
      assert.strictEqual(op.role, 'Operador');
    }
  });
});

describe('3. Dashboard e Monitoramento Geral', () => {
  test('GET /dashboard/summary - Retorna status, descrições do banco, KPIs de média horária e alertas', async () => {
    const res = await fetch(`${baseUrl}/dashboard/summary`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok('isSystemActive' in body);
    assert.ok(body.statusCardDescription);
    assert.ok(body.systemMetadata);
    assert.ok(Array.isArray(body.systemFeatures));
    assert.ok(body.nextIrrigation);
    assert.ok(body.kpis.waterConsumption);
    assert.ok(body.kpis.energyConsumption);
    assert.ok(body.kpis.efficiency);
    assert.ok(body.hourlySnapshot);
    assert.strictEqual(body.hourlySnapshot.intervalMinutes, 60);
    assert.ok(Array.isArray(body.criticalAlerts));
  });

  test('Cards da Dashboard permanecem estáticos durante os 59 minutos após resgate mesmo com novas leituras no monitoramento', async () => {
    // 1. Primeiro resgate consolida o snapshot de 1 hora
    const res1 = await fetch(`${baseUrl}/dashboard/summary`);
    const body1 = await res1.json();
    const initialWaterCard = body1.kpis.waterConsumption.value;
    const initialEnergyCard = body1.kpis.energyConsumption.value;

    // 2. Script Python / Sensor envia nova leitura no monitoramento
    await fetch(`${baseUrl}/monitoring/readings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sectorId: 'setor_a',
        moisture: 48.0,
        temperature: 27.0,
        waterConsumption: 68.0,
        energyConsumption: 64.0,
      }),
    });

    // 3. Consulta novamente dentro dos 59 minutos: valor deve permanecer estático
    const res2 = await fetch(`${baseUrl}/dashboard/summary`);
    const body2 = await res2.json();
    assert.strictEqual(body2.kpis.waterConsumption.value, initialWaterCard);
    assert.strictEqual(body2.kpis.energyConsumption.value, initialEnergyCard);
    assert.strictEqual(body2.hourlySnapshot.isStaticCache, true);
  });

  test('Alerta na Dashboard dispara apenas quando Setor tem Água, Energia e/ou Temperatura muito altos e normaliza depois', async () => {
    // 1. Envia leitura crítica (Água >= 80, Energia >= 100, Temperatura >= 35)
    const highRes = await fetch(`${baseUrl}/monitoring/readings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sectorId: 'setor_a',
        moisture: 40.0,
        temperature: 39.5,
        waterConsumption: 95.0,
        energyConsumption: 130.0,
      }),
    });
    assert.strictEqual(highRes.status, 201);
    const highBody = await highRes.json();
    assert.ok(highBody.triggeredAlert, 'Deve gerar alerta quando água, energia e temperatura estão muito altos');

    const dashHigh = await (await fetch(`${baseUrl}/dashboard/summary`)).json();
    const foundAlert = dashHigh.criticalAlerts.find(a => a.id === 'alert_threshold_setor_a');
    assert.ok(foundAlert, 'O alerta do Setor A deve aparecer na Dashboard');

    // 2. Normaliza valores do Setor A
    await fetch(`${baseUrl}/monitoring/readings`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sectorId: 'setor_a',
        moisture: 45.0,
        temperature: 28.0,
        waterConsumption: 45.0,
        energyConsumption: 42.0,
      }),
    });

    const dashNormal = await (await fetch(`${baseUrl}/dashboard/summary`)).json();
    const stillActive = dashNormal.criticalAlerts.find(a => a.id === 'alert_threshold_setor_a');
    assert.strictEqual(stillActive, undefined, 'Quando valores voltam ao normal, o alerta sai da Dashboard');
  });
});

describe('4. Gestão e Controle de Setores de Irrigação', () => {
  before(async () => {
    // Garante que setor_b comece como idle para o teste de toggle
    const db = require('../src/config/db');
    if (db.isDbConnected()) {
      await db.query("UPDATE sectors SET status = 'idle', flow_rate = 0 WHERE id = 'setor_b'");
    }
  });
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

  test('POST /sectors - Rejeita criação sem nome ou região com 400', async () => {
    const res = await fetch(`${baseUrl}/sectors`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: '', region: '' }),
    });
    assert.strictEqual(res.status, 400);
    const body = await res.json();
    assert.match(body.error, /obrigatórios/i);
  });

  test('POST /sectors - Cadastra novo setor com sucesso (201)', async () => {
    const uniqueSectorName = `Setor Teste ${Date.now().toString().slice(-4)}`;
    const res = await fetch(`${baseUrl}/sectors`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: uniqueSectorName,
        region: 'Noroeste',
        moisture: 48.0,
        temperature: 24.5,
      }),
    });
    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.strictEqual(body.name, uniqueSectorName);
    assert.strictEqual(body.region, 'Noroeste');
    assert.strictEqual(body.status, 'idle');
    assert.strictEqual(body.flowRate, 0);

    // Valida se o novo setor passa a ser retornado na listagem
    const listRes = await fetch(`${baseUrl}/sectors`);
    const sectors = await listRes.json();
    const created = sectors.find(s => s.name === uniqueSectorName);
    assert.ok(created, 'O novo setor deve estar presente na listagem');

    // Testa edição dos valores do setor (PUT /sectors/:id) com umidade ideal acima da atual (aciona irrigação automática)
    const editRes = await fetch(`${baseUrl}/sectors/${created.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: `${uniqueSectorName} Editado`,
        region: 'Norte-Central',
        idealMoisture: 65.0,
        minMoistureTrigger: 40.0,
        maxMoistureCutoff: 80.0,
        isEnabled: true,
      }),
    });
    assert.strictEqual(editRes.status, 200);
    const edited = await editRes.json();
    assert.strictEqual(edited.name, `${uniqueSectorName} Editado`);
    assert.strictEqual(edited.idealMoisture, 65.0);
    assert.strictEqual(edited.status, 'irrigating', 'Como umidade 48% < ideal 65%, irrigação ativa automaticamente');

    // Testa desativação do setor na chave Liga/Desliga (PUT /sectors/:id/enabled)
    const disableRes = await fetch(`${baseUrl}/sectors/${created.id}/enabled`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isEnabled: false }),
    });
    assert.strictEqual(disableRes.status, 200);
    const disabled = await disableRes.json();
    assert.strictEqual(disabled.isEnabled, false);
    assert.strictEqual(disabled.status, 'idle', 'Ao desativar o setor na chave Liga/Desliga, irrigação para');

    // Testa DELETE /sectors/:id (ao excluir no Controle, some da listagem e do Monitoramento)
    const delRes = await fetch(`${baseUrl}/sectors/${created.id}`, { method: 'DELETE' });
    assert.strictEqual(delRes.status, 200);

    const listAfterDel = await (await fetch(`${baseUrl}/sectors`)).json();
    const stillExists = listAfterDel.find(s => s.id === created.id);
    assert.strictEqual(stillExists, undefined, 'Setor excluído não deve aparecer na listagem');
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

  test('Snapshot e restauração dos setores ativos ao desligar e reativar o sistema', async () => {
    // 1. Garante que Setor B esteja irrigando antes da parada
    const sectorsInit = await (await fetch(`${baseUrl}/sectors`)).json();
    const bInit = sectorsInit.find(s => s.id === 'setor_b');
    if (bInit.status !== 'irrigating') {
      await fetch(`${baseUrl}/sectors/setor_b/toggle`, { method: 'POST' });
    }

    // 2. Aciona desligar tudo (emergency stop)
    const stopRes = await fetch(`${baseUrl}/irrigation/emergency-stop`, { method: 'POST' });
    assert.strictEqual(stopRes.status, 200);

    const sectorsDuringStop = await (await fetch(`${baseUrl}/sectors`)).json();
    assert.strictEqual(sectorsDuringStop.filter(s => s.status === 'irrigating').length, 0);

    // 3. Reativa o sistema e valida restauração do Setor B
    const resumeRes = await fetch(`${baseUrl}/irrigation/resume`, { method: 'POST' });
    assert.strictEqual(resumeRes.status, 200);
    const resumeBody = await resumeRes.json();
    assert.strictEqual(resumeBody.isSystemActive, true);

    const sectorsAfterResume = await (await fetch(`${baseUrl}/sectors`)).json();
    const sectorBAfter = sectorsAfterResume.find(s => s.id === 'setor_b');
    assert.strictEqual(sectorBAfter.status, 'irrigating');
    assert.ok(sectorBAfter.flowRate > 0);
  });

  test('Reativação automática do status na dashboard ao acionar qualquer setor individual', async () => {
    // 1. Aciona desligar tudo
    await fetch(`${baseUrl}/irrigation/emergency-stop`, { method: 'POST' });

    // 2. Liga Setor D individualmente
    const sectorsBeforeD = await (await fetch(`${baseUrl}/sectors`)).json();
    const dBefore = sectorsBeforeD.find(s => s.id === 'setor_d');
    if (dBefore.status !== 'irrigating') {
      await fetch(`${baseUrl}/sectors/setor_d/toggle`, { method: 'POST' });
    }

    // 3. Consulta summary da dashboard e valida status ativo imediato
    const dashRes = await fetch(`${baseUrl}/dashboard/summary`);
    const dash = await dashRes.json();
    assert.strictEqual(dash.isSystemActive, true);
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

  test('GET /irrigation/schedule - Retorna próximo horário e setores agendados', async () => {
    const res = await fetch(`${baseUrl}/irrigation/schedule`);
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok(body.time);
    assert.ok(body.sectors);
  });

  test('PUT /irrigation/schedule - Rejeita campos obrigatórios vazios com 400', async () => {
    const res = await fetch(`${baseUrl}/irrigation/schedule`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ time: '' }),
    });
    assert.strictEqual(res.status, 400);
  });

  test('PUT /irrigation/schedule - Atualiza horário e setores agendados com 200', async () => {
    const res = await fetch(`${baseUrl}/irrigation/schedule`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        time: '16:45',
        sectors: 'Setor A e B (Milho)',
        dailyProgressPct: 80.0,
      }),
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.schedule.time, '16:45');
    assert.strictEqual(body.schedule.sectors, 'Setor A e B (Milho)');
    assert.strictEqual(body.schedule.dailyProgressPct, 80.0);
  });

  test('CRUD de múltiplos agendamentos (/irrigation/schedules) - Adicionar, Editar, Desativar e Excluir', async () => {
    // 1. Cria novo agendamento
    const createRes = await fetch(`${baseUrl}/irrigation/schedules`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        time: '05:30',
        sectorIds: ['ALL'],
        sectorsLabel: 'Todos os Setores',
        isActive: true,
      }),
    });
    assert.strictEqual(createRes.status, 201);
    const created = await createRes.json();
    assert.strictEqual(created.time, '05:30');
    assert.strictEqual(created.isActive, true);

    // 2. Edita agendamento
    const editRes = await fetch(`${baseUrl}/irrigation/schedules/${created.id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        time: '07:15',
        sectorIds: ['setor_a', 'setor_b'],
        sectorsLabel: 'Setor A, Setor B',
        isActive: true,
      }),
    });
    assert.strictEqual(editRes.status, 200);
    const edited = await editRes.json();
    assert.strictEqual(edited.time, '07:15');
    assert.strictEqual(edited.sectorsLabel, 'Setor A, Setor B');

    // 3. Desativa agendamento (sem excluir)
    const toggleRes = await fetch(`${baseUrl}/irrigation/schedules/${created.id}/toggle`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ isActive: false }),
    });
    assert.strictEqual(toggleRes.status, 200);
    const toggled = await toggleRes.json();
    assert.strictEqual(toggled.isActive, false);

    // 4. Exclui agendamento
    const delRes = await fetch(`${baseUrl}/irrigation/schedules/${created.id}`, {
      method: 'DELETE',
    });
    assert.strictEqual(delRes.status, 200);
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
        energyConsumption: 38.0,
        waterConsumption: 44.0,
      }),
    });
    assert.strictEqual(res.status, 201);
  });

  test('GET /monitoring/sector-summary/:sectorId - Retorna médias de 1h (umidade e energia), 10min (temperatura e precipitação) e histórico horário', async () => {
    const res = await fetch(`${baseUrl}/monitoring/sector-summary/setor_a`);
    assert.strictEqual(res.status, 200);
    const summary = await res.json();
    assert.strictEqual(summary.sectorId, 'setor_a');
    assert.strictEqual(summary.hasData, true);
    assert.ok(summary.moisture1h);
    assert.strictEqual(summary.moisture1h.window, '1 hora');
    assert.ok(summary.energy1h);
    assert.strictEqual(summary.energy1h.window, '1 hora');
    assert.ok(summary.temperature10m);
    assert.strictEqual(summary.temperature10m.window, '10 minutos');
    assert.ok(summary.precipitation10m);
    assert.strictEqual(summary.precipitation10m.window, '10 minutos');
    assert.ok(Array.isArray(summary.hourlyChart));
    assert.ok(Array.isArray(summary.fullDayHistory));
  });

  test('DELETE /monitoring/clear & POST /monitoring/seed-history - Limpa banco e repopula dados via endpoint do script Python', async () => {
    // 1. Limpa todos os dados de telemetria
    const clearRes = await fetch(`${baseUrl}/monitoring/clear`, { method: 'DELETE' });
    assert.strictEqual(clearRes.status, 200);

    // Verifica que sem o script Python rodar, hasData fica false
    const emptySummary = await (await fetch(`${baseUrl}/monitoring/sector-summary/setor_a`)).json();
    assert.strictEqual(emptySummary.hasData, false);

    // 2. Repopula o histórico inicial (como faz o populate_telemetry.py ao iniciar)
    const seedRes = await fetch(`${baseUrl}/monitoring/seed-history`, { method: 'POST' });
    assert.strictEqual(seedRes.status, 201);
    const seedBody = await seedRes.json();
    assert.strictEqual(seedBody.success, true);

    // Verifica que agora hasData voltou para true
    const seededSummary = await (await fetch(`${baseUrl}/monitoring/sector-summary/setor_a`)).json();
    assert.strictEqual(seededSummary.hasData, true);
    assert.ok(seededSummary.hourlyChart.length > 0);
  });
});

describe('7. Relatórios e Exportação', () => {
  test('GET /reports/overview - Resumo mensal real do banco (comparativo vs mês anterior, ROI e gráfico de economia em R$)', async () => {
    const res = await fetch(`${baseUrl}/reports/overview`);
    assert.strictEqual(res.status, 200);
    const overview = await res.json();
    assert.ok(overview.summary);
    assert.ok('waterSavingsPct' in overview.summary);
    assert.ok('energySavingsPct' in overview.summary);
    assert.ok('estimatedRoiBrl' in overview.summary);
    assert.ok('previousMonthRoiBrl' in overview.summary);
    assert.ok('isRoiPositive' in overview.summary);
    assert.ok(Array.isArray(overview.monthlySavingsChart));
    assert.ok(overview.monthlySavingsChart.length > 0);
    assert.ok('totalSavingsBrl' in overview.monthlySavingsChart[0]);
    assert.ok(Array.isArray(overview.exportableReports));
  });

  test('GET /reports/export-pdf/monthly-savings - Download do gráfico de economia mensal em R$ (PDF)', async () => {
    const res = await fetch(`${baseUrl}/reports/export-pdf/monthly-savings`);
    assert.strictEqual(res.status, 200);
    const contentType = res.headers.get('content-type');
    assert.ok(contentType.includes('application/pdf'));
    const text = await res.text();
    assert.match(text, /^%PDF-1\.4/);
  });

  test('GET /reports/export/:id - Download de relatório real do banco em CSV e XLSX', async () => {
    const csvRes = await fetch(`${baseUrl}/reports/export/water_report?format=csv`);
    assert.strictEqual(csvRes.status, 200);
    assert.ok(csvRes.headers.get('content-type').includes('text/csv'));
    const csvText = await csvRes.text();
    assert.match(csvText, /Setor/);

    const xlsxRes = await fetch(`${baseUrl}/reports/export/energy_report?format=xlsx`);
    assert.strictEqual(xlsxRes.status, 200);
    assert.ok(xlsxRes.headers.get('content-type').includes('application/vnd.ms-excel'));
    const xlsxText = await xlsxRes.text();
    assert.match(xlsxText, /Workbook/);
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

describe('9. Gestão e Manipulação de Alertas no Banco de Dados', () => {
  let createdAlertId;

  test('GET /alerts - Lista alertas ativos do banco', async () => {
    const res = await fetch(`${baseUrl}/alerts`);
    assert.strictEqual(res.status, 200);
    const alerts = await res.json();
    assert.ok(Array.isArray(alerts));
  });

  test('POST /alerts - Rejeita criação sem título ou descrição com 400', async () => {
    const res = await fetch(`${baseUrl}/alerts`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: '' }),
    });
    assert.strictEqual(res.status, 400);
  });

  test('POST /alerts - Grava novo alerta no banco de dados com 201', async () => {
    const res = await fetch(`${baseUrl}/alerts`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: 'Alerta Teste Automatizado',
        description: 'Verificação de umidade em nível de atenção',
        severity: 'warning',
        sectorId: 'setor_b',
      }),
    });
    assert.strictEqual(res.status, 201);
    const body = await res.json();
    assert.ok(body.id);
    assert.strictEqual(body.title, 'Alerta Teste Automatizado');
    assert.strictEqual(body.isResolved, false);
    createdAlertId = body.id;
  });

  test('PUT /alerts/:id/resolve - Marca alerta como resolvido no banco', async () => {
    assert.ok(createdAlertId);
    const res = await fetch(`${baseUrl}/alerts/${createdAlertId}/resolve`, {
      method: 'PUT',
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.message, 'Alerta resolvido com sucesso');
    assert.strictEqual(body.alert.isResolved, true);
  });

  test('DELETE /alerts/:id - Remove alerta do banco de dados', async () => {
    assert.ok(createdAlertId);
    const res = await fetch(`${baseUrl}/alerts/${createdAlertId}`, {
      method: 'DELETE',
    });
    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.strictEqual(body.id, createdAlertId);
  });

  test('PUT /alerts/:id/resolve - Alerta inexistente retorna 404', async () => {
    const res = await fetch(`${baseUrl}/alerts/alert_inexistente_999/resolve`, {
      method: 'PUT',
    });
    assert.strictEqual(res.status, 404);
  });
});
