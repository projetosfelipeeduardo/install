# Instalador DigitalZap - Ubuntu 22.04

## 📋 Pré-requisitos

- Ubuntu 22.04 LTS (recomendado)
- Acesso root ou sudo
- Conexão com internet
- Domínios configurados (opcional para SSL)

## 🚀 Instalação

### 1. Baixar o instalador
```bash
git clone https://github.com/seu-repositorio/instalador-digitalzap.git
cd instalador-digitalzap
```

### 2. Executar como root
```bash
sudo ./install_ubuntu_22.04
```

### 3. Seguir as instruções interativas

O script irá solicitar:
- Senha para o usuário deploy
- Link do repositório Git
- Nome da instância
- Limites de usuários e conexões
- URLs do frontend e backend
- Portas para cada serviço

## 🔧 O que o instalador faz

### Sistema
- ✅ Atualiza o sistema
- ✅ Instala Node.js 20.x
- ✅ Instala Docker
- ✅ Instala PostgreSQL
- ✅ Instala PM2
- ✅ Instala Nginx
- ✅ Instala Certbot (SSL)
- ✅ Cria usuário deploy com privilégios sudo

### Backend
- ✅ Clona o repositório
- ✅ Configura variáveis de ambiente
- ✅ Cria banco PostgreSQL
- ✅ Instala Redis via Docker
- ✅ Instala dependências Node.js
- ✅ Executa migrações do banco
- ✅ Inicia com PM2
- ✅ Configura Nginx

### Frontend
- ✅ Configura variáveis de ambiente
- ✅ Instala dependências React
- ✅ Compila para produção
- ✅ Inicia com PM2
- ✅ Configura Nginx

### SSL/HTTPS
- ✅ Configura certificados Let's Encrypt
- ✅ Configura redirecionamentos HTTPS

## 🐛 Solução de Problemas

### Erro: "Usuário deploy já existe"
O script automaticamente remove e recria o usuário deploy.

### Erro: "Grupo sudo não encontrado"
O script verifica e cria o grupo sudo se necessário.

### Erro: "Permissão negada"
Execute o script como root:
```bash
sudo ./install_ubuntu_22.04
```

### Erro: "Porta já em uso"
Escolha portas diferentes durante a instalação:
- Frontend: 3000-3999
- Backend: 4000-4999
- Redis: 5000-5999

## 🔧 Problemas Específicos do Backend

### Erro: "Backend não inicia"
```bash
# 1. Verificar logs do PM2
sudo -u deploy pm2 logs [nome_instancia]-backend

# 2. Verificar status do PM2
sudo -u deploy pm2 status

# 3. Reiniciar backend
sudo -u deploy pm2 restart [nome_instancia]-backend
```

### Erro: "Conexão com banco falha"
```bash
# 1. Verificar se PostgreSQL está rodando
sudo systemctl status postgresql

# 2. Verificar se o banco existe
sudo -u postgres psql -l | grep [nome_instancia]

# 3. Recriar banco se necessário
sudo -u postgres psql -c "DROP DATABASE IF EXISTS [nome_instancia];"
sudo -u postgres psql -c "CREATE DATABASE [nome_instancia];"
```

### Erro: "Redis não conecta"
```bash
# 1. Verificar se container Redis está rodando
docker ps | grep redis-[nome_instancia]

# 2. Reiniciar container Redis
docker restart redis-[nome_instancia]

# 3. Verificar logs do Redis
docker logs redis-[nome_instancia]
```

### Erro: "Dependências não instalam"
```bash
# 1. Limpar cache do npm
sudo -u deploy npm cache clean --force

# 2. Remover node_modules e reinstalar
cd /home/deploy/[nome_instancia]/backend
sudo -u deploy rm -rf node_modules package-lock.json
sudo -u deploy npm install --force
```

### Erro: "Build falha"
```bash
# 1. Verificar se TypeScript está instalado
sudo -u deploy npm install -g typescript

# 2. Verificar scripts no package.json
sudo -u deploy cat package.json | grep -A 10 '"scripts"'

# 3. Executar build manualmente
sudo -u deploy npm run build
```

### Script de Diagnóstico
Use o script de diagnóstico para identificar problemas:
```bash
sudo ./debug_backend.sh [nome_instancia]
```

## 📁 Estrutura de Arquivos

```
instalador-digitalzap/
├── lib/                    # Funções principais
│   ├── _backend.sh        # Configuração backend
│   ├── _frontend.sh       # Configuração frontend
│   ├── _system.sh         # Configuração sistema
│   └── _inquiry.sh        # Interface usuário
├── variables/             # Variáveis e configurações
├── utils/                 # Utilitários
├── install_ubuntu_22.04   # Script principal Ubuntu 22.04
├── debug_backend.sh       # Script de diagnóstico
└── install_primaria       # Script original
```

## 🔄 Comandos de Gerenciamento

### Atualizar instância
```bash
sudo ./install_primaria
# Escolha opção 1
```

### Deletar instância
```bash
sudo ./install_primaria
# Escolha opção 2
```

### Bloquear/Desbloquear
```bash
sudo ./install_primaria
# Escolha opção 3 ou 4
```

### Alterar domínio
```bash
sudo ./install_primaria
# Escolha opção 5
```

## 📞 Suporte

Para suporte técnico, entre em contato com:
- Email: suporte@atendechat.com
- Website: https://atendechat.com

## 📄 Licença

Todos os direitos reservados a https://atendechat.com 