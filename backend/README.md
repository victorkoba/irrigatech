# IrrigaTech — Backend API & Database

Backend REST construído em **Node.js + Express** integrado com banco de dados **PostgreSQL** para o sistema inteligente de irrigação agrícola **IrrigaTech**.

---

## 🚀 Como Iniciar o Backend

1. Entre na pasta do backend:
   ```bash
   cd backend
   ```

2. Instale as dependências:
   ```bash
   npm install
   ```

3. Execute as migrations do banco de dados:
   ```bash
   npm run migrate
   ```

4. Inicie o servidor:
   ```bash
   # Modo desenvolvimento com auto-reload
   npm run dev

   # Ou modo produção
   npm start
   ```

O backend estará ativo em: **`http://localhost:3000`**

---

## 🧪 Testes Automatizados da API

A API conta com suíte nativa de testes de integração (`node:test` e `node:assert`):

```bash
npm test
```

* **Resultado:** 25 testes em 8 suítes com 100% de aprovação.
* Valida todas as rotas de autenticação, JWT, controle de setores, parada de emergência, modos de operação e tratamento de erros.

---

## 🗄️ Estrutura e Migrations do Banco de Dados

O projeto conta com um **sistema de versionamento de banco de dados (Migrations)** localizado em `backend/database/migrations/`:

* `001_create_schema.sql`: Provisiona todas as 8 tabelas com `CREATE TABLE IF NOT EXISTS`, chaves primárias, estrangeiras e índices telemétricos.
* `002_seed_initial_data.sql`: Carga idempotente de dados iniciais (operador padrão com hash bcrypt, setores, alertas, automação e métricas).

### Comandos de Banco de Dados

```bash
# Executar migrations pendentes
npm run migrate

# Popular banco com dados adicionais de simulação
npm run seed
```

> **Auto-Migração:** Ao inicializar a aplicação com o PostgreSQL ativo na porta 5432, o backend verifica e executa automaticamente qualquer migration pendente, garantindo integridade imediata sem necessidade de intervenção manual. Caso o PostgreSQL esteja offline, o sistema ativa o modo em memória de contingência.

---

## 📊 Tabelas Estruturadas no Banco

* **`users`**: Operadores e técnicos do sistema, hashes seguros `bcrypt` e permissões de acesso.
* **`sectors`**: Setores agrícolas (Norte, Sul, Leste, Oeste), cultura plantada, status (`irrigating`, `idle`, `error`), vazão e umidade.
* **`sensor_readings`**: Leituras em tempo real e série temporal de umidade do solo, temperatura e precipitação.
* **`automation_settings`**: Modos de operação (Automático/Manual), gatilhos de corte/ativação de umidade e status geral.
* **`alerts`**: Alertas críticos e advertências de vazamento ou umidade baixa.
* **`irrigation_events`**: Histórico detalhado de acionamentos e volume de água economizado/utilizado.
* **`productivity_metrics`**: Comparativo de sacas por hectare (Ciclo Atual vs. Ciclo Anterior) por talhão.
* **`weekly_consumption`**: Comparativo semanal de volume de água com variação percentual.
* **`schema_migrations`**: Registro de controle e idempotência das migrations executadas.

---

## 📡 Catálogo de Endpoints REST Principais

| Método | Endpoint | Descrição |
| :--- | :--- | :--- |
| `GET` | `/api/health` | Status do servidor e verificação de integridade |
| `POST` | `/api/auth/register` | Registro de novos operadores de campo |
| `POST` | `/api/auth/login` | Autenticação e emissão de token JWT |
| `GET` | `/api/dashboard/summary` | Resumo geral, KPIs, alertas críticos e próxima irrigação |
| `GET` | `/api/sectors` | Lista todos os setores com status, vazão e sensores |
| `POST` | `/api/sectors/:id/toggle` | Liga/Desliga a irrigação de um setor |
| `PUT` | `/api/sectors/:id/flow-rate` | Ajusta a vazão hidráulica (`m³/h`) de um setor |
| `POST` | `/api/irrigation/emergency-stop` | Parada de emergência: desliga imediatamente todos os setores |
| `POST` | `/api/irrigation/resume` | Reativa o sistema após parada de emergência |
| `PUT` | `/api/irrigation/mode` | Alterna modo entre `Automático` e `Manual` |
| `PUT` | `/api/irrigation/parameters` | Atualiza parâmetros de umidade mínima e máxima |
| `GET` | `/api/monitoring/readings/:id` | Histórico de 24 horas de leituras do setor |
| `GET` | `/api/monitoring/weekly-comparison`| Tabela comparativa semanal de consumo hídrico |
| `POST`| `/api/monitoring/readings` | Ingestão de novas leituras de sensores IoT |
| `GET` | `/api/reports/overview` | Métricas consolidadas de economia mensal, produtividade e ROI |
| `GET` | `/api/reports/export/:id` | Download de relatório em CSV/PDF |
