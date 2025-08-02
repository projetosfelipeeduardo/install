#!/bin/bash

# Script de diagnóstico para problemas do backend
# Uso: sudo ./debug_backend.sh [nome_instancia]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔍 Diagnóstico do Backend DigitalZap${NC}"
echo "=================================="

# Verificar se o nome da instância foi fornecido
if [ -z "$1" ]; then
    echo -e "${RED}Erro: Nome da instância não fornecido${NC}"
    echo "Uso: sudo ./debug_backend.sh [nome_instancia]"
    exit 1
fi

INSTANCIA=$1
BACKEND_PATH="/home/deploy/${INSTANCIA}/backend"

echo -e "${YELLOW}📋 Verificando instância: ${INSTANCIA}${NC}"
echo ""

# 1. Verificar se o usuário deploy existe
echo -e "${YELLOW}1. Verificando usuário deploy...${NC}"
if id "deploy" &>/dev/null; then
    echo -e "${GREEN}✅ Usuário deploy existe${NC}"
else
    echo -e "${RED}❌ Usuário deploy não existe${NC}"
    exit 1
fi

# 2. Verificar se o diretório existe
echo -e "${YELLOW}2. Verificando diretório do backend...${NC}"
if [ -d "$BACKEND_PATH" ]; then
    echo -e "${GREEN}✅ Diretório existe: $BACKEND_PATH${NC}"
else
    echo -e "${RED}❌ Diretório não existe: $BACKEND_PATH${NC}"
    exit 1
fi

# 3. Verificar arquivo .env
echo -e "${YELLOW}3. Verificando arquivo .env...${NC}"
if [ -f "$BACKEND_PATH/.env" ]; then
    echo -e "${GREEN}✅ Arquivo .env existe${NC}"
    echo "Conteúdo do .env:"
    sudo -u deploy cat "$BACKEND_PATH/.env" | head -10
else
    echo -e "${RED}❌ Arquivo .env não existe${NC}"
fi

# 4. Verificar package.json
echo -e "${YELLOW}4. Verificando package.json...${NC}"
if [ -f "$BACKEND_PATH/package.json" ]; then
    echo -e "${GREEN}✅ package.json existe${NC}"
    echo "Scripts disponíveis:"
    sudo -u deploy cat "$BACKEND_PATH/package.json" | grep -A 10 '"scripts"'
else
    echo -e "${RED}❌ package.json não existe${NC}"
fi

# 5. Verificar node_modules
echo -e "${YELLOW}5. Verificando node_modules...${NC}"
if [ -d "$BACKEND_PATH/node_modules" ]; then
    echo -e "${GREEN}✅ node_modules existe${NC}"
else
    echo -e "${RED}❌ node_modules não existe${NC}"
    echo "Execute: sudo -u deploy npm install"
fi

# 6. Verificar arquivo compilado
echo -e "${YELLOW}6. Verificando arquivo compilado...${NC}"
if [ -f "$BACKEND_PATH/dist/server.js" ]; then
    echo -e "${GREEN}✅ dist/server.js existe${NC}"
elif [ -f "$BACKEND_PATH/build/server.js" ]; then
    echo -e "${GREEN}✅ build/server.js existe${NC}"
else
    echo -e "${RED}❌ Arquivo compilado não encontrado${NC}"
    echo "Execute: sudo -u deploy npm run build"
fi

# 7. Verificar PostgreSQL
echo -e "${YELLOW}7. Verificando PostgreSQL...${NC}"
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$INSTANCIA"; then
    echo -e "${GREEN}✅ Banco de dados $INSTANCIA existe${NC}"
else
    echo -e "${RED}❌ Banco de dados $INSTANCIA não existe${NC}"
fi

# 8. Verificar Redis
echo -e "${YELLOW}8. Verificando Redis...${NC}"
if docker ps | grep -q "redis-$INSTANCIA"; then
    echo -e "${GREEN}✅ Container Redis redis-$INSTANCIA está rodando${NC}"
else
    echo -e "${RED}❌ Container Redis redis-$INSTANCIA não está rodando${NC}"
fi

# 9. Verificar PM2
echo -e "${YELLOW}9. Verificando PM2...${NC}"
if sudo -u deploy pm2 list | grep -q "$INSTANCIA-backend"; then
    echo -e "${GREEN}✅ Processo PM2 $INSTANCIA-backend existe${NC}"
    sudo -u deploy pm2 show "$INSTANCIA-backend"
else
    echo -e "${RED}❌ Processo PM2 $INSTANCIA-backend não existe${NC}"
fi

# 10. Verificar logs do PM2
echo -e "${YELLOW}10. Últimos logs do PM2...${NC}"
sudo -u deploy pm2 logs "$INSTANCIA-backend" --lines 10

# 11. Verificar conectividade do banco
echo -e "${YELLOW}11. Testando conexão com banco...${NC}"
cd "$BACKEND_PATH"
if sudo -u deploy npx sequelize db:version &>/dev/null; then
    echo -e "${GREEN}✅ Conexão com banco OK${NC}"
else
    echo -e "${RED}❌ Erro na conexão com banco${NC}"
fi

echo ""
echo -e "${GREEN}✅ Diagnóstico concluído!${NC}"
echo ""
echo -e "${YELLOW}💡 Comandos úteis:${NC}"
echo "  - Ver logs: sudo -u deploy pm2 logs $INSTANCIA-backend"
echo "  - Reiniciar: sudo -u deploy pm2 restart $INSTANCIA-backend"
echo "  - Parar: sudo -u deploy pm2 stop $INSTANCIA-backend"
echo "  - Status: sudo -u deploy pm2 status" 