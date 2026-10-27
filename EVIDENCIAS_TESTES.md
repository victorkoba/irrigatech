# IrrigaTech — Relatório Oficial de Evidências dos Testes Automatizados

Este documento consolida as evidências de execução dos testes automatizados desenvolvidos para o sistema **IrrigaTech**, comprovando a validação das camadas de backend (Node.js/Express) e frontend (Flutter).

---

## 1. Sumário Geral dos Testes

| Categoria | Suíte / Arquivo | Quantidade | Aprovados | Falhas | Status |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Backend API** | `backend/test/api.test.js` | 25 | 25 | 0 | **[Aprovado]** |
| **Frontend - Validações e Modelos** | `test/unit_models_test.dart` | 6 | 6 | 0 | **[Aprovado]** |
| **Frontend - Serviços e Regras** | `test/unit_services_test.dart` | 11 | 11 | 0 | **[Aprovado]** |
| **Frontend - Telas e Widgets** | `test/widget_auth_test.dart` | 5 | 5 | 0 | **[Aprovado]** |
| **Frontend - Navegação e Smoke** | `test/widget_test.dart` | 2 | 2 | 0 | **[Aprovado]** |
| **TOTAL CONSOLIDADO** | **Todas as suítes** | **49** | **49** | **0** | **100% SUCESSO** |

---

## 2. Evidências da Bateria de Testes do Backend (Node.js / Express)

Execução realizada no terminal através do comando:
```bash
npm test
```

### Evidência 1: Inicialização e Execução das Primeiras Suítes da API
*(Health Check, Autenticação, Cadastro, Dashboard e Gestão de Setores)*

![Evidência dos Testes Backend - Parte 1](docs/evidencias/evidencia_testes_backend_1.png)

### Evidência 2: Finalização das Suítes da API e Validação de 100% de Sucesso
*(Automação, Telemetria IoT, Relatórios, Erros 404 e Resultado Consolidado: 25 testes aprovados e 0 falhas)*

![Evidência dos Testes Backend - Parte 2](docs/evidencias/evidencia_testes_backend_2.png)

---

## 3. Evidências da Bateria de Testes do Frontend (Flutter)

Execução realizada através do comando:
```bash
flutter test
```

### Evidência 3: Execução das Suítes Unitárias, Regras de Negócio e Widgets do Flutter
*(Validações de formulário, modelos de dados, controle de irrigação, telas de login/cadastro, navegação e 24 testes aprovados)*

![Evidência dos Testes Frontend - Flutter](docs/evidencias/evidencia_testes_frontend.png)

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
| **Acionamento de Irrigação (Toggle)** | Integração / Unitário | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Bloqueio de Setor em Falha Mecânica** | Regra de Negócio | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Calibração de Vazão Hidráulica** | Integração / Unitário | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Parada Total de Emergência (Safety Stop)** | Segurança Crítica | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Reativação do Sistema (Resume)** | Automação | `backend/test/api.test.js` / `unit_services_test.dart` | **[Aprovado]** |
| **Telemetria de Umidade Contínua** | Telemetria IoT | `backend/test/api.test.js` | **[Aprovado]** |
| **Comparativo Semanal de Consumo** | Relatório Hídrico | `backend/test/api.test.js` | **[Aprovado]** |
| **Ingestão de Leituras de Sensores** | IoT Ingest | `backend/test/api.test.js` | **[Aprovado]** |
| **Exportação Estruturada em CSV** | Exportação | `backend/test/api.test.js` | **[Aprovado]** |
| **Tratamento de Rota Inexistente (404)** | Tratamento de Erro | `backend/test/api.test.js` | **[Aprovado]** |
| **Inicialização Segura do App (Smoke)** | Widget / UI | `test/widget_test.dart` | **[Aprovado]** |
| **Responsividade de Login e Cadastro** | Widget / UI | `test/widget_auth_test.dart` | **[Aprovado]** |

---

## 5. Conclusão Técnica

Todas as 49 verificações automatizadas foram concluídas com sucesso. A cobertura atesta a estabilidade do fluxo de controle de irrigação, tratamento de falhas e integridade da comunicação entre frontend e backend.
