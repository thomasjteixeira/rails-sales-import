# 📊 Sales Import System

Um sistema moderno de importação e processamento de vendas construído com Ruby on Rails, processamento assíncrono e interface responsiva.

🌐 **Deploy em produção:** [https://rails-sales-import-web.onrender.com/](https://rails-sales-import-web.onrender.com/)

## ✨ Funcionalidades

- 📁 **Importação de arquivos** (.tab, .tsv, .csv)
- ⚡ **Processamento assíncrono** com Sidekiq e Redis
- 📊 **Dashboard com estatísticas** de vendas
- 📈 **Histórico de importações** com status
- 🎯 **Validação robusta** de dados
- 📱 **Interface responsiva** com DaisyUI/Tailwind CSS
- 🔍 **Arquivos de exemplo** para testes
- 🚀 **Deploy automatizado** no Render
- 🧪 **SimpleCov** - Relatórios de cobertura de testes (98.37% de cobertura)

## 🛠️ Tecnologias Utilizadas

### Backend & Framework
- **Ruby on Rails 8.0.2** - Framework principal
- **SQLite3** - Banco de dados
- **Puma** - Servidor web
- **Active Storage** - Upload e gerenciamento de arquivos

### Processamento Assíncrono
- **Sidekiq** - Processamento de jobs em background
- **Redis** - Cache e message broker para Sidekiq
- **Dry-Monads** - Programação funcional e tratamento de erros

### Frontend & UI
- **Tailwind CSS** - Framework CSS utilitário
- **DaisyUI** - Componentes prontos para Tailwind
- **Turbo Rails** - SPA-like experience
- **Stimulus** - JavaScript framework

### Processamento de Dados
- **SmarterCSV** - Parser eficiente de arquivos CSV/TSV

### Desenvolvimento & Testes
- **RSpec** - Framework de testes
- **Factory Bot** - Factories para testes
- **Faker** - Dados fake para testes
- **Shoulda Matchers** - Matchers para RSpec
- **SimpleCov** - Cobertura de testes

### Deploy & DevOps
- **Docker** - Containerização
- **Render** - Plataforma de deploy

## 🚀 Instalação e Configuração

### Opção 1: Dev Containers (Recomendado) 🐳

**Pré-requisitos:**
- VS Code com extensão "Dev Containers"
- Docker Desktop instalado e rodando

**Setup:**
1. Clone o repositório e abra no VS Code
2. Aceite "Reopen in Container" ou pressione `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Aguarde a construção do container (primeira vez pode demorar)
4. Execute o setup do banco de dados:
   ```bash
   rails db:create && rails db:migrate && rails db:seed
   ```

**Vantagens:**
- ✅ Ambiente padronizado com Ruby 3.4.4, Node.js e Redis pré-configurados
- ✅ Ferramentas incluídas: `git`, `gh`, `docker`, `tree`, `find`, `grep`
- ✅ Isolamento completo do ambiente local

### Opção 2: Instalação Local

**Pré-requisitos:**
- Ruby 3.4.4+
- Node.js (para Tailwind CSS)
- Redis
- Docker (opcional)

**Clonando o repositório:**
```bash
git clone https://github.com/seu-usuario/rails-sales-import.git
cd rails-sales-import
```

**Instalação das dependências:**
```bash
# Instalar gems
bundle install
```

**Configuração do banco de dados:**
```bash
rails db:create
rails db:migrate
rails db:seed  # Carrega dados de exemplo
```

## 🏃‍♂️ Executando o Projeto

### Terminais Separados

**Terminal 1 - Rails Server:**

```bash
rails server -b 0.0.0.0 -p 3000
```

**Terminal 2 - Sidekiq (Processamento Assíncrono):**
```bash
REDIS_URL=redis://localhost:6379/0 bundle exec sidekiq -C config/sidekiq.yml
```

### Acessando a aplicação
- **Aplicação:** http://localhost:3000
- **Sidekiq Web UI:** http://localhost:3000/sidekiq

## 🔄 Processamento Assíncrono

O sistema utiliza **processamento assíncrono** para garantir performance e experiência do usuário


## 📁 Estrutura do Projeto

```
app/
├── controllers/
│   ├── dashboard_controller.rb     # Dashboard principal
│   ├── sample_files_controller.rb  # Download de exemplos
│   └── import_history_controller.rb # Histórico
├── models/
│   ├── sales_import.rb            # Modelo principal
│   ├── sale.rb                    # Venda individual
│   ├── purchaser.rb               # Comprador
│   ├── item.rb                    # Item/Produto
│   └── merchant.rb                # Lojista
├── services/
│   └── sales_imports/
│       ├── processor.rb           # Orquestrador principal
│       ├── file_parser.rb         # Parser de arquivos
│       └── sales_creator.rb       # Criação de vendas
├── jobs/
│   └── sales_import_processing_job.rb # Job assíncrono
└── views/
    ├── dashboard/                 # Interface principal
    └── import_history/            # Histórico
```

## 🧪 Executando Testes

```bash
rspec
```

## 📊 Monitoramento

### Sidekiq Web UI
Acesse http://localhost:3000/sidekiq para monitorar:
- Jobs em execução
- Filas de processamento
- Histórico de jobs
- Estatísticas de performance

## 🌐 Deploy em Produção

O projeto está configurado para deploy automático no **Render**:

### URL de Produção
**https://rails-sales-import-web.onrender.com/**

### Configurações de Deploy
- **Plataforma:** Render
- **Container:** Docker
- **Redis:** Render Redis addon
- **Storage:** Persistent disk para arquivos

## 📋 Formato dos Arquivos

### Estrutura Esperada (TSV/CSV)
```
purchaser name	item description	item price	purchase count	merchant address	merchant name
João Silva	Awesome Product	$34.18	2	123 Main St	Cool Store
```

### Arquivos de Exemplo
- **Valid Sample:** Arquivo com dados válidos
- **Invalid Sample:** Arquivo com erros para testar validação

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

**Desenvolvido com ❤️ usando Ruby on Rails e processamento assíncrono**
