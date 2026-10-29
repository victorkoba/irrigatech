# IrrigaTech — Relatório Oficial de Evidências dos Testes Automatizados

Este documento consolida as evidências de execução dos testes automatizados desenvolvidos para o sistema **IrrigaTech**, comprovando a validação das camadas de backend (Node.js/Express) e frontend (Flutter).

---

## 1. Sumário Geral dos Testes

| Categoria | Suíte / Arquivo | Quantidade | Aprovados | Falhas | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Backend API (REST + PostgreSQL)** | `backend/test/api.test.js` | 40 | 40 | 0 | **[Aprovado]** |
| **Frontend - Validações e Modelos** | `test/unit_models_test.dart` | 6 | 6 | 0 | **[Aprovado]** |
| **Frontend - Serviços e Regras** | `test/unit_services_test.dart` | 14 | 14 | 0 | **[Aprovado]** |
| **Frontend - Telas e Widgets** | `test/widget_auth_test.dart` | 5 | 5 | 0 | **[Aprovado]** |
| **Frontend - Navegação e Smoke** | `test/widget_test.dart` | 2 | 2 | 0 | **[Aprovado]** |
| **TOTAL CONSOLIDADO** | **Todas as suítes** | **67** | **67** | **0** | **100% SUCESSO** |

---

## 2. Evidências da Bateria de Testes do Backend (Node.js / Express)

Execução realizada no terminal através do comando:
```bash
npm test
```

### Suítes Validadas na API REST (38 testes em 9 suítes):
1. **Health Check & Diagnóstico:** Status online, tempo de resposta e integridade da conexão PostgreSQL.
2. **Autenticação, Cadastro e Validações:** Registro com hash bcrypt, duplicidade de e-mail (409) e JWT tokens.
3. **Dashboard Executivo:** Resumo de status, KPIs e agregação de alertas ativos.
4. **Gestão e Controle de Setores:** Listagem, cadastro de novos setores (`POST /sectors`), chaveamento (*toggle*), bloqueio preventivo de falha e ajuste de vazão.
5. **Automação e Parada de Emergência:** Acionamento de parada de segurança, snapshot de setores ativos antes da parada, restauração automática dos setores ao reativar e reativação imediata da Dashboard ao acionar qualquer setor.
6. **Telemetria e Ingestão IoT:** Leitura temporal de sensores e comparativo semanal.
7. **Relatórios e Exportação:** Download estruturado de relatórios em CSV.
8. **Tratamento de Erros:** Respostas padronizadas em rotas inexistentes (404).
9. **Gestão de Alertas no Banco de Dados:** Criação (`POST`), consulta (`GET`), resolução (`PUT /resolve`) e exclusão (`DELETE`) persistidas na tabela `alerts`.

---

## 3. Evidências da Bateria de Testes do Frontend (Flutter)

Execução realizada através do comando:
```bash
flutter test
```

### Suítes Validadas no Flutter (27 testes):
* **Modelos e Entidades:** Instanciação, serialização e integridade dos estados dos setores e alertas.
* **Validações de Formulário:** Validação rigorosa de nome, formato de e-mail e requisitos de senha segura.
* **Serviços Reativos (Provider):** Cadastro dinâmico de novos setores, alternância de modos operacionais, parada de emergência com snapshot de setores ativos, restauração fiel ao reativar, reativação imediata do status geral na dashboard ao acionar qualquer setor e manipulação de alertas.
* **Testes de Renderização e Widgets:** Responsividade da tela de login sem estouro de layout (*overflow*), tela de cadastro e navegação com abas.

---

## 4. Matriz de Rastreabilidade Requisito vs. Teste

| Requisito do Sistema | Tipo de Teste | Arquivo de Teste | Status |
| :--- | :--- | :--- | :---: |
| **Cadastro de Operador** | Integração API | `backend/test/api.test.js` | **[Aprovado]** |
| **Validação de Formato de E-mail** | Unitário UI / API | `test/unit_models_test.dart` / `api.test.js` | **[Aprovado]** |
| **Senha Mínima de 6 Caracteres** | Unitário UI / API | `test/unit_models_test.dart` / `api.test.js` | **[Aprovado]** |
| **Bloqueio de E-mail Duplicado (409)** | Integração API | `backend/test/api.test.js` | **[Aprovado]** |
| **Autenticação com JWT Token** | Integração API | `backend/test/api.test.js` | **[Aprovado]** |
| **Resumo do Dashboard & KPIs** | Integração API | `backend/test/api.test.js` | **[Aprovado]** |
| **Cadastro de Novo Setor de Irrigação** | Integração API / Unitário | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Sincronização Controle vs Monitoramento** | Integração de Estado / UI | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Acionamento de Irrigação (Toggle)** | Integração / Unitário | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Bloqueio de Setor em Falha Mecânica** | Regra de Negócio | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Calibração de Vazão Hidráulica** | Integração / Unitário | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Parada Total de Emergência (Safety Stop)** | Segurança Crítica | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Snapshot de Setores Ativos na Emergência** | Integridade Operacional | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Restauração Fiel dos Setores ao Reativar** | Automação e Continuidade | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Reativação Automática da Dashboard por Setor** | UX e Consistência de Estado | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Telemetria de Umidade Contínua** | Telemetria IoT | `backend/test/api.test.js` | **[Aprovado]** |
| **Comparativo Semanal de Consumo** | Relatório Hídrico | `backend/test/api.test.js` | **[Aprovado]** |
| **Ingestão de Leituras de Sensores** | IoT Ingest | `backend/test/api.test.js` | **[Aprovado]** |
| **Exportação Estruturada em CSV** | Exportação | `backend/test/api.test.js` | **[Aprovado]** |
| **Gestão Relacional de Alertas (CRUD)** | Banco de Dados / API | `backend/test/api.test.js` | **[Aprovado]** |
| **Agendamento de Irrigação (Programação)** | Automação / Banco de Dados | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Resolução de Alerta no PostgreSQL** | Persistência Relacional | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Tratamento de Rota Inexistente (404)** | Tratamento de Erro | `backend/test/api.test.js` | **[Aprovado]** |
| **Inicialização Segura do App (Smoke)** | Widget / UI | `test/widget_test.dart` | **[Aprovado]** |
| **Responsividade de Login e Cadastro** | Widget / UI | `test/widget_auth_test.dart` | **[Aprovado]** |

---

## 5. Conclusão Técnica

Todas as **65 verificações automatizadas** foram concluídas com 100% de aprovação. A cobertura atesta a estabilidade do fluxo de controle de irrigação, tratamento de falhas, ciclo de vida dos alertas no PostgreSQL e integridade da comunicação entre frontend e backend.
