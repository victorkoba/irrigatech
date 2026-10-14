# 🌱 IrrigaTech - Backend API & Database

Backend REST construído em **Node.js + Express** integrado com banco de dados **PostgreSQL** para o sistema inteligente de irrigação agrícola **IrrigaTech**.

---

## 🚀 Como Iniciar o Backend

1. Entre na pasta do backend:
   ```bash
   cd backend
   ```

2. Instale as dependências (já instaladas):
   ```bash
   npm install
   ```

3. Inicie o servidor:
   ```bash
   npm start
   # ou com auto-reload:
   npm run dev
   ```

O backend estará ativo em: **`http://localhost:3000`**

---

## 🗄️ Estrutura e Conexão do Banco de Dados (DBeaver)

Você pode conectar o **DBeaver** de duas formas:

### Opção 1: Subir o PostgreSQL via Docker (1 clique)
Na pasta `backend`, execute:
```bash
docker compose up -d
```
O container iniciará na porta `5432` e carregará automaticamente as tabelas e dados iniciais definidos em [`database/schema.sql`](./database/schema.sql).

### Opção 2: Conectar em um PostgreSQL existente via DBeaver
1. Abra o **DBeaver**.
2. Clique no botão **Nova Conexão** (ícone de tomada) e selecione **PostgreSQL**.
3. Preencha os dados de conexão:
   * **Host:** `localhost`
   * **Port:** `5432`
   * **Database:** `irrigatech`
   * **Username:** `postgres`
   * **Password:** `postgrespassword` *(ou a sua senha configurada no `.env`)*
4. Clique em **Testar Conexão** e depois em **Concluir**.
5. Abra um novo Script SQL no DBeaver (`Ctrl + ]`), cole o conteúdo de [`backend/database/schema.sql`](./database/schema.sql) e pressione `Alt + X` para executar!

---

## 📊 Tabelas Estruturadas no Banco

* **`sectors`**: Setores agrícolas (Norte, Leste, Sul...), cultura plantada, status (`irrigating`, `idle`, `error`), vazão e umidade.
* **`sensor_readings`**: Leituras em tempo real e série temporal de umidade do solo, temperatura e precipitação.
* **`automation_settings`**: Modos de operação (Automático/Manual), gatilhos de corte/ativação de umidade e status geral.
* **`alerts`**: Alertas críticos e advertências de vazamento/umidade baixa.
* **`irrigation_events`**: Histórico detalhado de acionamentos e volume de água economizado/utilizado.
* **`productivity_metrics`**: Comparativo de sacas por hectare (Ciclo Atual vs. Ciclo Anterior) por talhão.
* **`weekly_consumption`**: Comparativo semanal de volume de água com variação percentual.

---

## 📡 Catálogo de Endpoints REST

| Método | Endpoint | Descrição |
| :--- | :--- | :--- |
| `GET` | `/api/health` | Status do servidor e conexão com o banco |
| `GET` | `/api/dashboard/summary` | Resumo geral, KPIs, alertas críticos e próxima irrigação |
| `GET` | `/api/sectors` | Lista todos os setores com status, vazão e sensores |
| `POST` | `/api/sectors/:id/toggle` | Liga/Desliga a irrigação de um setor |
| `PUT` | `/api/sectors/:id/flow-rate` | Ajusta a vazão (`m³/h`) de um setor |
| `POST` | `/api/irrigation/emergency-stop` | **Parada de emergência**: desliga todos os setores |
| `POST` | `/api/irrigation/resume` | Reativa o sistema |
| `PUT` | `/api/irrigation/mode` | Alterna modo entre `Automático` e `Manual` |
| `PUT` | `/api/irrigation/parameters` | Atualiza parâmetros de umidade mínima e máxima |
| `GET` | `/api/monitoring/readings/:id` | Histórico de 24 horas de leituras do setor |
| `GET` | `/api/monitoring/weekly-comparison`| Tabela comparativa semanal de consumo |
| `POST`| `/api/monitoring/readings` | Ingestão de novas leituras de sensores IoT |
| `GET` | `/api/reports/overview` | Métricas de economia mensal, produtividade e conformidade |
| `GET` | `/api/reports/export/:id` | Download de relatório em CSV/PDF |
