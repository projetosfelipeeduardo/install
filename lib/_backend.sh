#!/bin/bash
#
# functions for setting up app backend
#######################################
# creates REDIS db using docker
# Arguments:
#   None
#######################################
backend_redis_create() {
  print_banner
  printf "${WHITE} 💻 Criando Redis & Banco Postgres...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  # Garantir que o usuário deploy está no grupo docker
  usermod -aG docker deploy
  
  # Parar e remover container Redis se existir
  docker stop redis-${instancia_add} 2>/dev/null || true
  docker rm redis-${instancia_add} 2>/dev/null || true
  
  # Criar container Redis
  docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always --detach redis redis-server --requirepass ${mysql_root_password}
  
  sleep 2
  
  # Configurar PostgreSQL
  sudo -u postgres psql -c "DROP DATABASE IF EXISTS ${instancia_add};"
  sudo -u postgres psql -c "DROP USER IF EXISTS ${instancia_add};"
  sudo -u postgres psql -c "CREATE USER ${instancia_add} WITH SUPERUSER INHERIT CREATEDB CREATEROLE PASSWORD '${mysql_root_password}';"
  sudo -u postgres psql -c "CREATE DATABASE ${instancia_add} OWNER ${instancia_add};"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${instancia_add} TO ${instancia_add};"
EOF

  sleep 2
}

#######################################
# sets environment variable for backend.
# Arguments:
#   None
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  # ensure idempotency
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url

  # Criar diretório se não existir
  sudo su - deploy <<EOF
  mkdir -p /home/deploy/${instancia_add}/backend
EOF

  # Criar arquivo .env com formatação correta
  sudo su - deploy <<EOF
  cat > /home/deploy/${instancia_add}/backend/.env << 'ENVEOF'
NODE_ENV=production
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=${backend_port}

DB_DIALECT=postgres
DB_HOST=localhost
DB_PORT=5432
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}
CLOSED_SEND_BY_ME=true
ENVEOF
EOF

  sleep 2
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  
  # Verificar se package.json existe
  if [ ! -f "package.json" ]; then
    echo "Erro: package.json não encontrado!"
    exit 1
  fi
  
  # Limpar cache do npm se necessário
  npm cache clean --force
  
  # Instalar dependências
  npm install --force --no-audit
  
  # Verificar se a instalação foi bem-sucedida
  if [ \$? -ne 0 ]; then
    echo "Erro na instalação das dependências!"
    exit 1
  fi
EOF

  sleep 2
}

#######################################
# compiles backend code
# Arguments:
#   None
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  
  # Verificar se node_modules existe
  if [ ! -d "node_modules" ]; then
    echo "Erro: node_modules não encontrado! Execute npm install primeiro."
    exit 1
  fi
  
  # Verificar se o script build existe no package.json
  if ! grep -q '"build"' package.json; then
    echo "Erro: Script 'build' não encontrado no package.json!"
    exit 1
  fi
  
  # Limpar build anterior
  rm -rf dist build
  
  # Executar build
  npm run build
  
  # Verificar se o build foi bem-sucedido
  if [ \$? -ne 0 ]; then
    echo "Erro no build do backend!"
    exit 1
  fi
  
  # Verificar se o arquivo compilado existe
  if [ ! -f "dist/server.js" ] && [ ! -f "build/server.js" ]; then
    echo "Erro: Arquivo compilado não encontrado!"
    exit 1
  fi
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${empresa_atualizar}
  pm2 stop ${empresa_atualizar}-backend
  git pull
  cd /home/deploy/${empresa_atualizar}/backend
  npm install
  npm update -f
  npm install @types/fs-extra
  rm -rf dist 
  npm run build
  npx sequelize db:migrate
  npx sequelize db:migrate
  npx sequelize db:seed
  pm2 start ${empresa_atualizar}-backend
  pm2 save 
EOF

  sleep 2
}

#######################################
# runs db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  
  # Verificar se o arquivo .env existe
  if [ ! -f ".env" ]; then
    echo "Erro: Arquivo .env não encontrado!"
    exit 1
  fi
  
  # Verificar conexão com o banco
  echo "Verificando conexão com o banco de dados..."
  npx sequelize db:version || {
    echo "Erro: Não foi possível conectar ao banco de dados!"
    echo "Verifique as configurações no arquivo .env"
    exit 1
  }
  
  # Executar migrações
  echo "Executando migrações..."
  npx sequelize db:migrate
  
  # Verificar se as migrações foram bem-sucedidas
  if [ \$? -ne 0 ]; then
    echo "Erro nas migrações do banco de dados!"
    exit 1
  fi
EOF

  sleep 2
}

#######################################
# runs db seed
# Arguments:
#   None
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Executando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  npx sequelize db:seed:all
EOF

  sleep 2
}

#######################################
# starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  
  # Verificar se o arquivo compilado existe
  if [ -f "dist/server.js" ]; then
    SERVER_FILE="dist/server.js"
  elif [ -f "build/server.js" ]; then
    SERVER_FILE="build/server.js"
  else
    echo "Erro: Arquivo server.js não encontrado em dist/ ou build/!"
    exit 1
  fi
  
  # Parar processo PM2 se já estiver rodando
  pm2 stop ${instancia_add}-backend 2>/dev/null || true
  pm2 delete ${instancia_add}-backend 2>/dev/null || true
  
  # Verificar se o PM2 está instalado
  if ! command -v pm2 &> /dev/null; then
    echo "Erro: PM2 não está instalado!"
    exit 1
  fi
  
  # Iniciar aplicação com PM2
  echo "Iniciando backend com PM2..."
  pm2 start \$SERVER_FILE --name ${instancia_add}-backend --time
  
  # Verificar se o PM2 iniciou corretamente
  if [ \$? -ne 0 ]; then
    echo "Erro ao iniciar o backend com PM2!"
    exit 1
  fi
  
  # Salvar configuração do PM2
  pm2 save
  
  # Mostrar status
  pm2 status
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${instancia_add}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}
