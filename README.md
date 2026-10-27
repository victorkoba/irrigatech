# IrrigaTech — Sistema Inteligente de Irrigação Agrícola

Plataforma integrada de Internet das Coisas (IoT), automação de pivôs de irrigação, telemetria de umidade de solo e inteligência sustentável para o agronegócio.

---

## Como Executar a Aplicação Completa

A solução é composta por **três camadas integradas**:
1. **Banco de Dados Relacional:** PostgreSQL 14+ (Docker ou instalação local na porta `5432`).
2. **Back-end de Automação:** API REST em Node.js / Express na porta `3000`.
3. **Front-end Responsivo:** Aplicativo em Flutter (Web Chrome, Mobile Android e Desktop).

---

### Pré-requisitos
* [Node.js](https://nodejs.org/) (versão 18.x ou superior) e `npm`
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versão 3.13.3 ou superior)
* [Docker Desktop](https://www.docker.com/) *(opcional, recomendado para subir o PostgreSQL em 1 clique)* ou PostgreSQL local na porta 5432
* [Git](https://git-scm.com/)
* Navegador **Google Chrome** (para execução Web) ou **Emulador Android / VS Code**

---

### 1. Inicializar o Banco de Dados e Migrations

Abra um terminal no diretório do projeto:

```bash
# 1. Navegue até a pasta do backend
cd backend

# 2. Suba o container PostgreSQL (caso utilize Docker)
docker compose up -d

# 3. Instale as dependências do backend
npm install

# 4. Execute as migrations para provisionar tabelas e dados iniciais
npm run migrate
```

> **Nota de Resiliência:** O backend possui arquitetura de dupla resiliência: caso o PostgreSQL não esteja rodando, ele chaveia automaticamente para o modo em memória (*in-memory fallback*), permitindo testar o app mesmo sem banco ativo. Com o PostgreSQL ativo, as migrations são verificadas e aplicadas automaticamente na inicialização.

---

### 2. Executar e Testar o Back-end

No diretório `backend`:

```bash
# Iniciar a API em modo desenvolvimento (auto-reload)
npm run dev

# Ou em modo produção
npm start

# Executar a bateria de testes automatizados de integração (25 testes)
npm test
```

* API REST ativa em: **`http://localhost:3000`**
* Health Check: **`http://localhost:3000/api/health`**

---

### 3. Executar e Testar o Front-end (Flutter)

Abra outro terminal na raiz do projeto (`irrigatech`):

```bash
# 1. Instalar as dependências do Flutter
flutter pub get

# 2. Executar os testes automatizados da interface e modelos (24 testes)
flutter test

# 3. Executar o aplicativo no Google Chrome
flutter run -d chrome

# Ou em dispositivo Android
# flutter run -d android
```

---

### Credenciais Padrão de Acesso

Ao abrir a tela de Login no aplicativo ou autenticar via API (`POST /api/auth/login`):
* **E-mail:** `operador@irrigatech.com`
* **Senha:** `123456`
* *Ou cadastre uma nova conta diretamente na tela de Registro do aplicativo!*

---

### Documentação Técnica e Entregáveis

Os manuais de engenharia, especificações técnicas e evidências de testes estão disponíveis em formato Markdown no repositório:

| Documento | Formato | Descrição |
|:---|:---:|:---|
| **Manual da API REST** | [MD](./DOCUMENTACAO_API.md) | Catálogo de endpoints, contratos JSON e especificações de integração |
| **Evidências de Testes** | [MD](./EVIDENCIAS_TESTES.md) | Relatório de 49 testes automatizados (unitários, integração e widgets) |
| **Registro de Engenharia** | [MD](./REGISTRO_DIFICULDADES_DECISOES.md) | Dificuldades enfrentadas, decisões de arquitetura e mudanças de escopo |

> **Nota:** As versões compiladas em PDF para entrega executiva e as capturas de evidências em imagem são armazenadas externamente na pasta `Documents/irrigatech_entregaveis` e nos downloads locais (`irrigatech_database.sql`).

---

## Sobre o projeto

A IrrigaTech é um **Sistema Inteligente para o Agronegócio**, uma solução de automação e monitoramento inteligente da irrigação agrícola, desenvolvida para reduzir o desperdício de água e energia, melhorar a produtividade e facilitar o gerenciamento das propriedades rurais.

A proposta combina **Internet das Coisas (IoT), sensores, automação, conectividade em campo, computação em nuvem e aplicativo mobile** para transformar o processo de irrigação manual em um sistema baseado em dados e decisões automatizadas.

## Problema

A utilização de sistemas de irrigação manuais no agronegócio pode gerar:

* Alto consumo de água;
* Desperdício de energia elétrica;
* Custos operacionais elevados;
* Baixa precisão no manejo da irrigação;
* Dependência de intervenções manuais;
* Dificuldade de acompanhamento das condições do solo e do clima;
* Falta de dados históricos para análise de desempenho;
* Dificuldade na mensuração dos resultados de produtividade e economia.

## Solução

O projeto propõe um sistema capaz de **monitorar as condições da área agrícola em tempo real e automatizar o processo de irrigação** de acordo com os dados coletados.

Sensores instalados no campo serão responsáveis pela coleta de informações como **umidade do solo, temperatura, umidade relativa do ar e precipitação**. Esses dados serão processados pelo sistema para determinar a necessidade de irrigação.

Visando sempre reduzir a necessidade de intervenção humana e falhas do processo manual.

O produtor também poderá acompanhar as informações e controlar o sistema remotamente por meio de um **aplicativo mobile**, permitindo maior praticidade e controle da operação.

## Etapas Operacionais

1. **Coleta:** sensores captam informações do solo e das condições climáticas.
2. **Transmissão:** os dados são enviados ao sistema por meio da conectividade disponível no campo.
3. **Processamento:** o backend analisa os dados recebidos e consulta parâmetros agronômicos.
4. **Automação:** o sistema determina a necessidade de irrigação e aciona/desliga as válvulas.
5. **Monitoramento:** o produtor acompanha as informações e alertas pelo aplicativo.
6. **Relatórios:** o sistema registra dados históricos e apresenta indicadores de consumo e desempenho.

## Relatórios e Indicadores

O sistema permite a geração de relatórios automáticos para facilitar a análise dos resultados:

* Consumo de água em m³;
* Economia percentual de água;
* Consumo de energia em kWh;
* Economia percentual de energia;
* Tempo de funcionamento da irrigação;
* Histórico de acionamentos e paradas de segurança;
* Condições de umidade do solo por setor;
* Evolução da produtividade (sacas/ha).

## Usuários e Stakeholders

### Usuários principais
**Produtores rurais e gestores de propriedades agrícolas** responsáveis pelo acompanhamento e gerenciamento da irrigação.

### Usuários secundários e stakeholders
* Equipe técnica e operacional de campo;
* Gestores corporativos do agronegócio;
* Órgãos de certificação ambiental;
* Instituições financeiras para crédito rural verde.

## Equipe

| Nº | Integrante |
| -: | :--- |
| 01 | Enrico Augusto Pereira Naba |
| 02 | João Gustavo Mota Ramos |
| 03 | João Pedro da Cunha Machado |
| 04 | Rodrigo Santos Graça |
| 05 | Victor Luiz Koba Batista |
| 06 | Vitório Fraga Motta |

---

**IrrigaTech / AgroFlow**
*Tecnologia aplicada para uma irrigação mais inteligente, eficiente e sustentável.*
