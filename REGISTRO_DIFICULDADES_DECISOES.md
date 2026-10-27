# IrrigaTech — Registro de Dificuldades, Decisões Técnicas e Mudanças de Escopo

Documento de Engenharia de Software, Arquitetura e Gestão Operacional do Projeto

---

## 1. Sumário Executivo

Este documento consolida o histórico de desenvolvimento do projeto **IrrigaTech**, registrando os desafios técnicos enfrentados pela equipe de engenharia, as decisões arquiteturais adotadas para superá-los e as adaptações de escopo realizadas ao longo do ciclo de entrega.

O objetivo deste registro é garantir a rastreabilidade das escolhas técnicas, documentar lições aprendidas e demonstrar a evolução contínua da maturidade do ecossistema, composto por:
* **Aplicativo Mobile/Web:** Interface responsiva em Flutter com gerenciamento de estado reativo.
* **Backend de Automação:** API REST em Node.js/Express com dupla resiliência de dados e migrations automáticas.
* **Banco de Dados Relacional:** PostgreSQL com modelagem de telemetria, integridade referencial e versionamento declarativo.
* **Garantia de Qualidade:** Bateria de 49 testes automatizados (unitários, integração e widgets com 100% de aprovação).

---

## 2. Registro de Dificuldades Enfrentadas

### 2.1. Inconsistência de Estado no Fallback In-Memory em Paradas de Emergência
* **Descrição do Problema:** Durante a execução do comando crítico de Parada de Emergência (`POST /api/irrigation/emergency-stop`), a flag global do sistema era alterada para inativa, porém os registros dos setores mantidos em memória continuavam com status operacional de irrigação ativa (`status: 'irrigating'`).
* **Impacto Operacional:** Essa inconsistência causava falha imediata nos testes automatizados de integração e, em um cenário de campo, representaria um risco operacional ao reportar falsamente que as válvulas ainda estavam abertas após um comando de corte emergencial.
* **Solução Implementada:** Desenvolveu-se a função dedicada `stopAllFallbackSectors()` no controlador de setores (`sectorController.js`), que é acionada de forma coordenada pelo controlador de irrigação (`irrigationController.js`). Essa rotina força a atualização atômica de todos os setores para `status: 'idle'` e `flowRate: 0.0`, garantindo paridade entre o banco relacional e a contingência em memória.

### 2.2. Omissão da Tabela de Usuários no Schema Relacional Inicial
* **Descrição do Problema:** O script DDL inicial `backend/database/schema.sql` e o script de carga `seeder.sql` continham as tabelas de setores, telemetria e eventos, mas não declaravam a tabela relacional `users`.
* **Impacto Operacional:** Qualquer tentativa de registrar novos operadores ou autenticar via banco PostgreSQL resultava em erro de execução SQL por tabela inexistente (`relation "users" does not exist`).
* **Solução Implementada:** O schema foi reestruturado com a adição da tabela `users`, contemplando chave primária serial, campos de controle de acesso (`name`, `email` único, `password` com hash bcrypt, `role` operacional e timestamps). Foi também atualizado o script idempotente `seed.js` e gerado o script consolidado de exportação para carga direta no PostgreSQL.

### 2.3. Estouro de Layout (RenderFlex Overflow) no Flutter em Telas Compactas
* **Descrição do Problema:** Na tela de autenticação (`login_screen.dart`), os links inferiores de rodapé para alternância entre telas estavam dispostos em uma `Row` rígida. Em dispositivos móveis com viewports verticais reduzidas ou teclados virtuais abertos, o Flutter acusava estouro de layout de 32 pixels.
* **Impacto Operacional:** O erro quebrava a experiência visual em smartphones compactos e ocasionava falha nos testes de renderização de widgets.
* **Solução Implementada:** Substituiu-se a `Row` rígida por um componente `Wrap` com espaçamento adaptativo e envolveu-se a árvore de visualização em um `SingleChildScrollView`, eliminando qualquer possibilidade de estouro em telas pequenas ou em modo paisagem.

### 2.4. Resolução de Dependências em Testes de Interface (ProviderNotFoundException)
* **Descrição do Problema:** Ao executar a suíte de testes de widgets (`flutter test`), o teste de fumaça da árvore principal falhava com exceção de provider ausente, pois o widget `IrrigaTechApp` referenciava o `AuthService` que não estava presente na árvore de injeção dos testes isolados.
* **Impacto Operacional:** Impossibilidade de validar a navegação e o carregamento do shell de abas de forma automatizada.
* **Solução Implementada:** Os testes de widgets foram refatorados para envelopar a árvore testada com `MultiProvider`, instanciando simultaneamente `AuthService` e `IrrigationService`, espelhando a configuração de produção presente no arquivo de inicialização `main.dart`.

### 2.5. Dependência de Módulo Criptográfico em Ambiente Isolado
* **Descrição do Problema:** A execução da suíte de testes do backend reportava erro de módulo ausente para a biblioteca `bcryptjs`.
* **Impacto Operacional:** Bloqueio das rotinas de testes de autenticação.
* **Solução Implementada:** Realizou-se a auditoria do arquivo de manifesto `package.json`, reinstalação limpa via `npm install` no diretório do backend e fixação das versões das dependências para assegurar reprodutibilidade imediata em qualquer ambiente de desenvolvimento.

### 2.6. Falha em Banco PostgreSQL Pré-existente por Ausência de Migrations Incrementais
* **Descrição do Problema:** Quando o PostgreSQL foi iniciado na porta 5432, o backend conectou com sucesso, desativando o modo de contingência em memória. No entanto, uma instância legada do banco de dados continha apenas as 7 tabelas originais criadas antes da implementação do módulo de autenticação. Sem um pipeline de migração incremental, a execução de `npm test` gerava o erro `relation "users" does not exist` em 5 testes de autenticação.
* **Impacto Operacional:** Divergência de schema entre o código da aplicação e a base relacional persistida, impedindo o login e o registro de novos operadores no banco de dados ativo.
* **Solução Implementada:** Criação de um sistema formal de versionamento de banco de dados (Migrations) em `backend/database/migrations/`, com runner autônomo `migrate.js`, tabela de controle `schema_migrations`, comando `npm run migrate` e rotina de auto-migração na conexão inicial do backend. Com isso, todas as 25 suítes de testes foram aprovadas com 100% de sucesso com o PostgreSQL conectado.

---

## 3. Decisões Técnicas e Arquiteturais

### 3.1. Arquitetura de Dupla Resiliência (Dual-Mode Backend)
* **Contexto:** Ambientes agrícolas frequentemente operam em condições de conectividade instável, e ambientes de teste ou demonstração técnica podem não dispor de uma instância local do PostgreSQL ativa.
* **Decisão Adotada:** Implementar um mecanismo inteligente de chaveamento transparente no módulo `backend/src/config/db.js`. O backend tenta estabelecer conexão com o pool do PostgreSQL (`pg.Pool`). Caso o banco não responda na porta 5432, o sistema migra automaticamente para o modo de contingência in-memory seguro, pré-populado com os mesmos setores e operadores padrão.
* **Benefício:** Garantia de disponibilidade ininterrupta (Zero Downtime). O aplicativo Flutter nunca fica inoperante por falta de banco relacional local, mantendo a experiência fluida tanto para operadores em campo quanto para testes de desenvolvimento.

### 3.2. Adoção do Test Runner Nativo do Node.js (`node:test`)
* **Contexto:** Havia a necessidade de estabelecer uma bateria robusta de testes de integração na API REST que validasse todos os status HTTP (200, 201, 400, 401, 404, 409) e regras de negócio.
* **Decisão Adotada:** Utilizar exclusivamente os módulos nativos `node:test` e `node:assert`, disponíveis a partir do Node.js 18+, dispensando bibliotecas externas pesadas como Jest, Mocha ou Chai.
* **Benefício:** Redução expressiva de dependências de terceiros, eliminação de vulnerabilidades em cadeia, tempo de execução ultrarrápido (25 testes executados em menos de 1 segundo) e compatibilidade imediata com qualquer esteira de integração contínua (CI/CD).

### 3.3. Gerenciamento de Estado Reativo com o Padrão Provider
* **Contexto:** O aplicativo de supervisão requer atualização em tempo real de cards telemétricos, status de pivôs e alternância de modos operacionais, com reflexo imediato entre telas distintas (Dashboard, Controle de Irrigação e Monitoramento).
* **Decisão Adotada:** Adotar o `ChangeNotifierProvider` como padrão central de gerência de estado no Flutter, desacoplando completamente os serviços de dados (`ApiService`, `IrrigationService`, `AuthService`) dos componentes de interface visual.
* **Benefício:** Facilidade de manutenção, independência de código para criação de testes unitários sem acoplamento à UI e propagação reativa eficiente de eventos de campo.

### 3.4. Exportação Autônoma e Idempotente do Banco de Dados
* **Contexto:** Para entrega e implantação facilitada em ferramentas administrativas como DBeaver, pgAdmin ou containers Docker, a base de dados precisava ser reprodutível com um único comando.
* **Decisão Adotada:** Criar um script SQL estruturado e transacional (`irrigatech_database.sql`), contendo bloco `BEGIN ... COMMIT`, deleção segura de tabelas pré-existentes (`DROP TABLE IF EXISTS ... CASCADE`), criação das 8 tabelas relacionais com chaves estrangeiras e índices, finalizando com o seed de dados operacionais completos.
* **Benefício:** Facilidade de carga no banco de dados, sem necessidade de configuração prévia ou execução de comandos adicionais no terminal.

### 3.5. Segregação Modular de Documentos Técnicos
* **Contexto:** A especificação do projeto exigia documentação de fluxo operacional, contrato de API e evidências de testes de qualidade.
* **Decisão Adotada:** Dividir as entregas em artefatos dedicados e independentes:
  * `FLUXO_PRINCIPAL.pdf`: Focado na visão executiva, jornada do usuário de ponta a ponta e etapas operacionais.
  * `DOCUMENTACAO_API.pdf` e `.md`: Focado no contrato dos endpoints, exemplos de payloads e evidências visuais no Postman.
  * `EVIDENCIAS_TESTES.pdf` e `.md`: Focado nos resultados de execução dos testes automatizados (49 testes aprovados) e capturas de terminal.
  * `REGISTRO_DIFICULDADES_DECISOES.pdf` e `.md`: Focado nas decisões de engenharia, desafios e lições aprendidas.
* **Benefício:** Clareza na comunicação, permitindo que diferentes perfis de avaliadores e desenvolvedores encontrem exatamente a informação necessária sem redundâncias.

### 3.6. Sistema Nativo de Migrations Versionadas e Idempotentes
* **Contexto:** O ciclo de vida de uma aplicação em produção exige atualização segura e incremental do schema do banco de dados relacional sem quebrar bases legadas ou perder dados existentes.
* **Decisão Adotada:** Criar uma infraestrutura nativa de migrations (`backend/database/migrations/` e `migrate.js`) com controle transacional e rastreamento na tabela `schema_migrations`. Além do comando explícito `npm run migrate`, o backend dispara uma verificação de auto-migração transparente sempre que o pool do PostgreSQL é estabelecido com sucesso.
* **Benefício:** Idempotência total, sincronismo imediato entre código e schema relacional, e zero atrito na integração de novos desenvolvedores ou em ambientes de homologação.

---

## 4. Registro de Mudanças de Escopo

### 4.1. Foco do Catálogo de Endpoints nos Casos de Uso Críticos Validados
* **Escopo Original:** O planejamento preliminar sugeria documentar dezenas de rotinas analíticas e de ingestão de séries temporais que ainda demandam integração com hardware físico de sensores em campo.
* **Mudança Realizada:** O escopo da documentação ativa de endpoints foi refinado para contemplar os 10 endpoints de operação direta validados via Postman (autenticação de operadores, diagnóstico, telemetria de painel, controle de válvulas, vazão hidráulica, corte de emergência e parametrização).
* **Justificativa:** Garantir 100% de precisão e rastreabilidade entre as evidências visuais fornecidas e o contrato documentado, eliminando endpoints com comportamentos puramente teóricos.

### 4.2. Inclusão da Bateria de Testes Automatizados no Escopo de Entrega
* **Escopo Original:** Inicialmente o projeto não contava com testes automatizados estruturados e com evidências formais de execução.
* **Mudança Realizada:** Foi concebida e implementada uma infraestrutura abrangente com 49 testes automatizados:
  * 25 testes de integração no Backend cobrindo todas as rotas e códigos de retorno HTTP.
  * 24 testes no Frontend em Flutter cobrindo modelos de dados, validação de formulários, regras de negócio de irrigação e renderização de telas de autenticação e navegação.
* **Justificativa:** Assegurar que o fluxo de ponta a ponta permaneça íntegro contra regressões e comprovar a robustez técnica do software com evidências verificáveis.

### 4.3. Implementação de Ajuste de Vazão Hidráulica Individual por Setor
* **Escopo Original:** O controle de setores contemplava apenas o chaveamento binário (Ligar / Desligar).
* **Mudança Realizada:** Adicionou-se o endpoint `PUT /api/sectors/:id/flow-rate`, permitindo que o operador module numericamente o fluxo de água de acordo com a necessidade hídrica específica de cada cultura.
* **Justificativa:** Aumentar a fidelidade agronômica da plataforma e atender ao requisito de economia e eficiência no uso de recursos hídricos.

### 4.4. Padronização Estrita da Documentação Técnica
* **Escopo Original:** Documentos técnicos livres, sem regras rígidas de apresentação.
* **Mudança Realizada:** Estabeleceu-se uma política estrita de formatação em todas as entregas técnicas:
  * Remoção completa de emojis e ícones informais.
  * Omissão de dados temporais voláteis (datas e horários) para conferir longevidade às especificações.
  * Omissão de nomes individuais de autores para foco institucional no produto.
  * Compilação dos documentos em PDF profissional através de renderização headless com margens e folhas padronizadas.
* **Justificativa:** Conformidade com padrões formais de documentação de engenharia de software e relatórios corporativos.

### 4.5. Implementação de Versionamento Declarativo de Banco de Dados via Migrations
* **Escopo Original:** Inicialização do banco dependente de execução de scripts SQL monolíticos no DBeaver.
* **Mudança Realizada:** Elevação da gestão de banco para um pipeline automatizado de schema migrations com versionamento incremental (`001_create_schema.sql`, `002_seed_initial_data.sql`), rastreado no próprio PostgreSQL.
* **Justificativa:** Eliminar falhas por divergência de schema e permitir atualizações automáticas e seguras em qualquer base de dados conectada.

---

## 5. Matriz Resumo de Decisões e Impacto

| Item | Área Afetada | Decisão Adotada | Impacto / Resultado |
|:---|:---|:---|:---|
| **D1** | Backend / Banco | Chaveamento automático PostgreSQL / In-Memory | Zero Downtime e flexibilidade total de execução |
| **D2** | Qualidade | Utilização de `node:test` e `node:assert` nativos | 25 testes de integração em menos de 1 segundo |
| **D3** | Segurança | Hash de senhas com `bcryptjs` e validação 409 | Proteção de credenciais e conformidade com boas práticas |
| **D4** | Interface Flutter | Gerenciamento de estado reativo com `Provider` | Desacoplamento entre lógica de negócios e UI |
| **D5** | Layout Flutter | Substituição de `Row` por `Wrap` e scroll flexível | Eliminação de estouros de tela em dispositivos compactos |
| **D6** | Banco de Dados | Script SQL único e transacional para exportação | Facilidade de carga no DBeaver / pgAdmin sem atrito |
| **D7** | Operação Crítica | Função atômica de corte em parada de emergência | Sincronia perfeita entre status de segurança e atuadores |
| **D8** | Governança | Segregação dos entregáveis em 4 documentos temáticos | Rastreabilidade e fácil leitura por diferentes públicos |
| **D9** | Banco de Dados / CI | Sistema de Migrations Versionadas (`migrate.js`) | Atualização incremental automática e 100% dos testes aprovados com PostgreSQL conectado |

---

*IrrigaTech — Registro de Decisões de Arquitetura e Engenharia de Software.*
