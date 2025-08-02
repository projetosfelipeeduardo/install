#!/bin/bash

# Script de instalação simplificado para Ubuntu 22.04
# Uso: sudo ./install_simple.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Instalador DigitalZap - Ubuntu 22.04${NC}"
echo "=========================================="

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script deve ser executado como root (sudo)${NC}"
   exit 1
fi

# Obter diretório do script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Verificar se todos os arquivos necessários existem
echo -e "${YELLOW}🔍 Verificando arquivos necessários...${NC}"

REQUIRED_FILES=(
    "lib/_backend.sh"
    "lib/_frontend.sh"
    "lib/_system.sh"
    "lib/_inquiry.sh"
    "variables/_app.sh"
    "variables/_fonts.sh"
    "utils/_banner.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Todos os arquivos necessários encontrados${NC}"

# Definir PROJECT_ROOT
export PROJECT_ROOT="$SCRIPT_DIR"

# Verificar versão do Ubuntu
UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "unknown")
echo -e "${YELLOW}📋 Versão do Ubuntu detectada: $UBUNTU_VERSION${NC}"

if [[ "$UBUNTU_VERSION" != "22.04" ]]; then
   echo -e "${YELLOW}⚠️  Aviso: Este script foi otimizado para Ubuntu 22.04${NC}"
   read -p "Deseja continuar mesmo assim? (y/N): " -n 1 -r
   echo
   if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
   fi
fi

# Carregar bibliotecas
echo -e "${YELLOW}📚 Carregando bibliotecas...${NC}"
source "${PROJECT_ROOT}"/variables/manifest.sh
source "${PROJECT_ROOT}"/utils/manifest.sh
source "${PROJECT_ROOT}"/lib/manifest.sh

# Configurar arquivo de configuração
echo -e "${YELLOW}⚙️  Configurando arquivo de configuração...${NC}"
if [[ ! -e "${PROJECT_ROOT}"/config ]]; then
  cat << EOF > "${PROJECT_ROOT}"/config
deploy_password=
mysql_root_password=
db_pass=${db_pass}
EOF
fi

# Configurar permissões
chown root:root "${PROJECT_ROOT}"/config
chmod 700 "${PROJECT_ROOT}"/config
source "${PROJECT_ROOT}"/config

# Verificações pré-instalação
echo -e "${YELLOW}🔍 Verificando sistema...${NC}"

# Verificar se o sistema está atualizado
if ! apt list --upgradable 2>/dev/null | grep -q .; then
   echo -e "${GREEN}✅ Sistema está atualizado${NC}"
else
   echo -e "${YELLOW}⚠️  Sistema precisa de atualizações. Atualizando...${NC}"
   apt update && apt upgrade -y
fi

# Verificar se o usuário deploy já existe e remover se necessário
if id "deploy" &>/dev/null; then
   echo -e "${YELLOW}⚠️  Usuário deploy já existe. Removendo...${NC}"
   userdel -r deploy 2>/dev/null || true
fi

# Verificar e criar grupo sudo se necessário
if ! getent group sudo > /dev/null 2>&1; then
   echo -e "${YELLOW}⚠️  Grupo sudo não encontrado. Criando...${NC}"
   groupadd sudo
fi

echo -e "${GREEN}✅ Verificações concluídas${NC}"
echo ""

# Iniciar instalação
echo -e "${GREEN}🚀 Iniciando instalação...${NC}"

# Interface interativa
inquiry_options

# Dependências do sistema
echo -e "${YELLOW}📦 Instalando dependências do sistema...${NC}"
system_update
system_node_install
system_pm2_install
system_docker_install
system_puppeteer_dependencies
system_snapd_install
system_nginx_install
system_certbot_install

# Configuração do sistema
echo -e "${YELLOW}👤 Configurando usuário deploy...${NC}"
system_create_user

# Backend
echo -e "${YELLOW}🔧 Configurando backend...${NC}"
system_git_clone
backend_set_env
backend_redis_create
backend_node_dependencies
backend_node_build
backend_db_migrate
backend_db_seed
backend_start_pm2
backend_nginx_setup

# Frontend
echo -e "${YELLOW}🎨 Configurando frontend...${NC}"
frontend_set_env
frontend_node_dependencies
frontend_node_build
frontend_start_pm2
frontend_nginx_setup

# Rede
echo -e "${YELLOW}🌐 Configurando rede...${NC}"
system_nginx_conf
system_nginx_restart
system_certbot_setup

echo ""
echo -e "${GREEN}✅ Instalação concluída com sucesso!${NC}"
echo -e "${GREEN}🔗 Acesse seu sistema em: ${frontend_url}${NC}"
echo ""
echo -e "${YELLOW}💡 Comandos úteis:${NC}"
echo "  - Ver logs: sudo -u deploy pm2 logs"
echo "  - Status: sudo -u deploy pm2 status"
echo "  - Reiniciar: sudo -u deploy pm2 restart all" 