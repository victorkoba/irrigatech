# IrrigaTech — Manual de Referência da API REST
Documentação Técnica de Integração, Contrato de Endpoints e Conexão de Banco de Dados

---

## 1. Sumário Executivo

A **API REST do IrrigaTech** é a espinha dorsal de comunicação entre o aplicativo de gestão agrícola (Flutter) e o ecossistema de controle de pivôs, sensores de umidade de solo e atuadores de campo. 

O sistema conta com **arquitetura de dupla resiliência**:
1. **Modo Integrado PostgreSQL (DBeaver / Docker):** Conexão ativa via pool de conexões (`pg.Pool`) com persistência relacional transacional e integridade referencial.
2. **Modo de Contingência (In-Memory Seguro):** Em caso de indisponibilidade momentânea da base de dados, o backend chaveia de forma transparente para estruturas em memória pré-populadas, garantindo **disponibilidade contínua de 100% (Zero Downtime)** para operadores em campo.

---

## 2. Configuração e Execução

### 1. Variáveis de Ambiente (`backend/.env`)

```env
PORT=3000

# Conexão PostgreSQL (Local / DBeaver / Docker)
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=postgrespassword
DB_NAME=irrigatech

# String de Conexão Unificada
DATABASE_URL=postgresql://postgres:postgrespassword@localhost:5432/irrigatech

# Segurança JWT
JWT_SECRET=irrigatech-dev-secret-troque-em-producao
```

### 2. Comandos de Inicialização

```bash
# Navegar até a pasta backend
cd backend

# Instalar dependências
npm install

# Iniciar servidor em produção
npm start

# Iniciar servidor com auto-reload
npm run dev

# Executar bateria de testes automatizados com evidências
npm test

# Popular banco de dados PostgreSQL com dados realistas
npm run seed
```

---

## 3. Estrutura do Banco de Dados PostgreSQL (DBeaver)

O banco de dados relacional é estruturado em 8 tabelas principais, definidas em `backend/database/schema.sql`:

```mermaid
erDiagram
    users ||--o{ irrigation_events : monitors
    sectors ||--o{ sensor_readings : records
    sectors ||--o{ alerts : generates
    sectors ||--o{ irrigation_events : triggers
    automation_settings ||--|| sectors : coordinates
    productivity_metrics }|--|| sectors : evaluates
    weekly_consumption }|--|| sectors : measures

    users {
        int id PK
        string name
        string email UK
        string password_hash
        string role
        timestamp created_at
    }

    sectors {
        string id PK
        string name
        string region
        string crop
        string status
        numeric flow_rate
        numeric moisture
        numeric temperature
        string alert_message
    }

    sensor_readings {
        bigint id PK
        string sector_id FK
        numeric moisture
        numeric temperature
        numeric precipitation
        timestamp recorded_at
    }

    alerts {
        string id PK
        string sector_id FK
        string title
        text description
        string severity
        boolean is_resolved
    }

    automation_settings {
        int id PK
        boolean is_system_active
        string operation_mode
        numeric min_moisture_trigger
        numeric max_moisture_cutoff
        string next_irrigation_time
        numeric daily_progress_pct
    }
```

### Conexão via DBeaver
1. Abra o **DBeaver**.
2. Conexão: **PostgreSQL**.
3. Parâmetros:
   - **Host:** `localhost`
   - **Porta:** `5432`
   - **Banco:** `irrigatech`
   - **Usuário:** `postgres`
   - **Senha:** `postgrespassword`
4. Execute o script `backend/database/schema.sql` e em seguida `backend/database/seeder.sql`.

---

## 4. Catálogo Completo de Endpoints & Evidências Postman

### 1. Diagnóstico do Sistema (Health Check)

#### `GET /api/health`
Retorna a saúde operacional do servidor, versão da API e o status da conexão ativa com o banco PostgreSQL.

* **Evidência no Postman:**
![Postman GET Health](docs/postman/postman_health.png)

* **Especificação do Retorno:**
```json
{
  "status": "online",
  "appName": "IrrigaTech Backend API",
  "version": "1.0.0",
  "database": {
    "connected": false,
    "type": "PostgreSQL",
    "host": "localhost",
    "database": "irrigatech",
    "dbeaverReady": true
  }
}
```

---

### 2. Autenticação e Gestão de Acesso

#### `POST /api/auth/register`
Realiza o cadastro de novos operadores agrícolas no sistema com validação de formato de e-mail e hash seguro da senha.

* **Evidência no Postman:**
![Postman POST Register](docs/postman/postman_register.png)

* **Especificação do Retorno (201 Created):**
```json
{
  "message": "Conta criada com sucesso.",
  "user": {
    "id": 3,
    "name": "Operador",
    "email": "operador@gmail.com",
    "role": "operator"
  }
}
```

* **Respostas de Erro:**
  - `400 Bad Request`: `{"error": "Preencha nome, e-mail e senha."}`
  - `400 Bad Request`: `{"error": "E-mail inválido."}`
  - `400 Bad Request`: `{"error": "A senha precisa ter pelo menos 6 caracteres."}`
  - `409 Conflict`: `{"error": "Este e-mail já está cadastrado."}`

---

#### `POST /api/auth/login`
Autentica o operador com validação criptográfica da senha via bcrypt e emissão de token JWT.

* **Evidência no Postman:**
![Postman POST Login](docs/postman/postman_login.png)

* **Especificação do Retorno (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 3,
    "name": "Operador",
    "email": "operador@gmail.com",
    "role": "operator"
  }
}
```

* **Respostas de Erro:**
  - `401 Unauthorized`: `{"error": "E-mail ou senha incorretos."}`

---

### 3. Dashboard Executivo e KPIs

#### `GET /api/dashboard/summary`
Retorna um panorama consolidado da fazenda: status geral, agendamento de irrigação, indicadores-chave de desempenho (água, energia, eficiência) e lista de alertas ativos.

* **Evidência no Postman:**
![Postman GET Dashboard Summary](docs/postman/postman_dashboard.png)

* **Especificação do Retorno (200 OK):**
```json
{
  "isSystemActive": true,
  "nextIrrigation": {
    "time": "14:30",
    "sectors": "Setores B e D (Milho)",
    "dailyProgressPct": 65
  },
  "kpis": {
    "waterConsumption": { "value": "1.2k", "unit": "m³/h", "trend": "-5% vs ontem" },
    "energyConsumption": { "value": "450", "unit": "kWh", "trend": "+2% vs ontem" },
    "efficiency": { "value": "94", "unit": "%", "trend": "Excelente" }
  },
  "criticalAlerts": [
    {
      "id": "alert_1",
      "title": "Umidade baixa no Setor A",
      "description": "Níveis abaixo de 15%. Irrigação de emergência recomendada.",
      "severity": "critical"
    }
  ]
}
```

---

### 4. Controle e Gestão de Setores

#### `GET /api/sectors`
Lista todos os setores agrícolas da fazenda com status operacional (`irrigating`, `idle`, `error`), telemetria hídrica e mensagens de advertência.

* **Evidência no Postman:**
![Postman GET Sectors](docs/postman/postman_sectors.png)

* **Especificação do Retorno (200 OK):**
```json
[
  {
    "id": "setor_a",
    "name": "Setor A",
    "region": "Norte",
    "status": "irrigating",
    "flowRate": 45,
    "moisture": 45,
    "temperature": 28
  },
  {
    "id": "setor_c",
    "name": "Setor C",
    "region": "Sul",
    "status": "error",
    "flowRate": 0,
    "moisture": 18,
    "temperature": 31,
    "alertMessage": "Vazamento Detectado"
  }
]
```

---

#### `POST /api/sectors`
Cadastra um novo setor de irrigação no sistema (persistido no PostgreSQL).
* **Campos Obrigatórios:** `name` (string) e `region` (string).
* **Campos Opcionais:** `moisture` (numeric, default 50.0), `temperature` (numeric, default 25.0).

* **Corpo da Requisição (Body):**
```json
{
  "name": "Setor F",
  "region": "Noroeste",
  "moisture": 52.0,
  "temperature": 24.5
}
```

* **Especificação do Retorno (201 Created):**
```json
{
  "id": "setor_setor_f_1234",
  "name": "Setor F",
  "region": "Noroeste",
  "status": "idle",
  "flowRate": 0,
  "moisture": 52,
  "temperature": 24.5,
  "alertMessage": null
}
```

---

#### `POST /api/sectors/:id/toggle`
Liga ou desliga a irrigação de um setor específico.  
* **Regra de Segurança:** Setores em estado `error` (ex.: vazamento, pane mecânica) são estritamente bloqueados contra acionamento acidental.

* **Evidência no Postman:**
![Postman POST Toggle Sector](docs/postman/postman_toggle.png)

* **Especificação do Retorno (200 OK):**
```json
{
  "id": "setor_a",
  "name": "Setor A",
  "region": "Norte",
  "status": "irrigating",
  "flowRate": 40,
  "moisture": 45,
  "temperature": 28
}
```

---

#### `PUT /api/sectors/:id/flow-rate`
Ajusta finamente a vazão hidráulica de um setor em operação.

* **Evidência no Postman:**
![Postman PUT Flow Rate](docs/postman/postman_flow_rate.png)

* **Corpo da Requisição (Body):**
```json
{
  "flowRate": 74.73
}
```

* **Exemplo de Resposta (200 OK):**
```json
{
  "id": "setor_a",
  "name": "Setor A",
  "region": "Norte",
  "status": "irrigating",
  "flowRate": 74.73309608540917,
  "moisture": 45,
  "temperature": 28
}
```

---

### 5. Automação e Parada de Emergência

#### `POST /api/irrigation/emergency-stop`
Protocolo de corte total de água:
1. **Snapshot de Estado:** Salva o snapshot dos setores que estavam em operação ativa (`status = 'irrigating'`) e suas respectivas vazões hídricas (`flow_rate`) antes da interrupção.
2. **Corte Total:** Desliga instantaneamente todos os setores em irrigação (`status: idle`, `flowRate: 0.0`) e desativa a operação global (`is_system_active = false`) por segurança.

* **Evidência no Postman:**
![Postman POST Emergency Stop](docs/postman/postman_emergency_stop.png)

* **Especificação do Retorno (200 OK):**
```json
{
  "message": "Parada de emergência executada.",
  "isSystemActive": false,
  "savedSectors": [
    {
      "id": "setor_a",
      "flow_rate": 45.0
    }
  ]
}
```

---

#### `POST /api/irrigation/resume`
Reativa os solenoides e circuitos de automação após normalização de emergência:
1. **Restauração Inteligente:** Recupera os setores salvos no snapshot anterior e restabelece a irrigação (`status = 'irrigating'`) com suas vazões originais.
2. **Sincronização de Status:** Atualiza `automation_settings.is_system_active = true` e notifica o painel. Caso nenhum setor estivesse ativo no momento do stop, reativa o setor primário por padrão.

* **Exemplo de Resposta (200 OK):**
```json
{
  "message": "Sistema reativado.",
  "isSystemActive": true,
  "restoredSectors": [
    {
      "id": "setor_a",
      "flow_rate": 45.0
    }
  ]
}
```

> [!NOTE]
> **Reativação Automática por Acionamento Individual:** Caso o operador ative manualmente qualquer setor individualmente (via `POST /api/sectors/:id/toggle` ou Switch na interface) enquanto o sistema estiver em estado suspenso, o status geral do sistema é reativado imediatamente para `SISTEMA ATIVO`, garantindo total consistência na Dashboard.

---

#### `PUT /api/irrigation/mode`
Alterna a inteligência do sistema entre controle autônomo baseado em sensores (`Automático`) ou acionamento pelo operador (`Manual`).

* **Evidência no Postman:**
![Postman PUT Mode](docs/postman/postman_mode.png)

* **Especificação do Retorno (200 OK):**
```json
{
  "operationMode": "Manual"
}
```

---

#### `PUT /api/irrigation/parameters`
Configura os gatilhos agronômicos de umidade do solo: corte mínimo para ligar e teto máximo de saturação para corte.

* **Evidência no Postman:**
![Postman PUT Parameters](docs/postman/postman_parameters.png)

* **Especificação do Retorno (200 OK):**
```json
{
  "minMoistureTrigger": 30,
  "maxMoistureCutoff": 90
}
```

---

#### `GET /api/irrigation/schedule`
Retorna a programação da próxima irrigação gravada no banco de dados relacional na tabela `automation_settings`.

* **Especificação do Retorno (200 OK):**
```json
{
  "time": "14:30",
  "sectors": "Setores B e D (Milho)",
  "dailyProgressPct": 65.0
}
```

---

#### `PUT /api/irrigation/schedule`
Atualiza a programação da próxima irrigação diretamente no PostgreSQL, refletindo em tempo real tanto no banner da Dashboard quanto na aba de Controle.

* **Payload de Envio (JSON):**
```json
{
  "time": "16:45",
  "sectors": "Setores A e B (Milho)",
  "dailyProgressPct": 80.0
}
```

* **Especificação do Retorno (200 OK):**
```json
{
  "message": "Agendamento de irrigação atualizado com sucesso",
  "schedule": {
    "time": "16:45",
    "sectors": "Setores A e B (Milho)",
    "dailyProgressPct": 80.0
  }
}
```

---

### 6. Gestão e Manipulação de Alertas no Banco de Dados

Os alertas operacionais e críticos da fazenda são gravados e manipulados de forma relacional na tabela `alerts` do PostgreSQL, garantindo rastreabilidade, histórico de auditoria e resolução em tempo real.

#### `GET /api/alerts`
Retorna a lista de alertas ativos do banco de dados (por padrão `is_resolved = false`). Permite o parâmetro opcional `?all=true` para auditoria histórica de alertas já resolvidos.

* **Especificação do Retorno (200 OK):**
```json
[
  {
    "id": "alert_1",
    "sectorId": "setor_a",
    "title": "Umidade baixa no Setor A",
    "description": "Níveis abaixo de 15%. Irrigação de emergência recomendada.",
    "severity": "critical",
    "isResolved": false,
    "createdAt": "2026-10-27T22:00:00.000Z",
    "timestamp": "2026-10-27T22:00:00.000Z"
  }
]
```

---

#### `POST /api/alerts`
Grava um novo alerta no banco de dados emitido por rotinas de telemetria IoT ou operadores de campo.

* **Payload de Envio (JSON):**
```json
{
  "title": "Pressão irregular na linha mestre",
  "description": "Sensor de pressão indicou queda súbita no Setor B.",
  "severity": "warning",
  "sectorId": "setor_b"
}
```

* **Especificação do Retorno (201 Created):**
```json
{
  "id": "alert_1793150215399_952",
  "sectorId": "setor_b",
  "title": "Pressão irregular na linha mestre",
  "description": "Sensor de pressão indicou queda súbita no Setor B.",
  "severity": "warning",
  "isResolved": false,
  "createdAt": "2026-10-27T22:15:00.000Z",
  "timestamp": "2026-10-27T22:15:00.000Z"
}
```

---

#### `PUT /api/alerts/:id/resolve`
Marca o alerta como resolvido no banco de dados (`is_resolved = true`), atualizando o status na base relacional e retirando-o automaticamente do badge de pendências e da lista de alertas críticos do Dashboard.

* **Especificação do Retorno (200 OK):**
```json
{
  "message": "Alerta resolvido com sucesso",
  "alert": {
    "id": "alert_1",
    "sectorId": "setor_a",
    "title": "Umidade baixa no Setor A",
    "description": "Níveis abaixo de 15%. Irrigação de emergência recomendada.",
    "severity": "critical",
    "isResolved": true,
    "createdAt": "2026-10-27T22:00:00.000Z",
    "timestamp": "2026-10-27T22:00:00.000Z"
  }
}
```

---

#### `DELETE /api/alerts/:id`
Exclui fisicamente o registro do alerta da tabela relacional `alerts` no PostgreSQL.

* **Especificação do Retorno (200 OK):**
```json
{
  "message": "Alerta removido com sucesso",
  "id": "alert_1"
}
```

---

## 5. Tratamento Padronizado de Erros

A API adota rigorosamente as convenções HTTP RFC 7231 e formata todas as mensagens de erro em JSON:

| Código | Significado | Situação Típica |
|:---|:---|:---|
| `200 OK` | Sucesso | Consulta, atualização ou ação executada |
| `201 Created` | Criado | Novo usuário registrado ou leitura de sensor ingerida |
| `400 Bad Request` | Erro de Validação | Falta de campos obrigatórios, formato inválido, acionamento de setor em erro |
| `401 Unauthorized` | Não Autenticado | E-mail ou senha inválidos |
| `404 Not Found` | Não Encontrado | Rota inexistente ou ID de recurso inválido |
| `409 Conflict` | Conflito | Tentativa de cadastro de e-mail já existente |
| `500 Server Error` | Erro Interno | Falha inesperada de infraestrutura |

---
*IrrigaTech — Tecnologia e Inteligência Sustentável para o Agronegócio.*
