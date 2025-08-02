#!/bin/bash

# Script para corrigir permissões e formatação
# Uso: sudo ./fix_permissions.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🔧 Corrigindo permissões e formatação${NC}"
echo "====================================="

# Verificar se está rodando como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script deve ser executado como root (sudo)${NC}"
   exit 1
fi

# Obter diretório do script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

echo -e "${YELLOW}📁 Corrigindo permissões dos arquivos...${NC}"

# Lista de arquivos executáveis
EXECUTABLE_FILES=(
    "install_ubuntu_22.04"
    "installubuntu"
    "install_simple.sh"
    "install_primaria"
    "install_instancia"
    "debug_backend.sh"
    "fix_permissions.sh"
)

# Lista de diretórios
DIRECTORIES=(
    "lib"
    "variables"
    "utils"
)

# Corrigir permissões dos arquivos executáveis
for file in "${EXECUTABLE_FILES[@]}"; do
    if [ -f "$file" ]; then
        chmod +x "$file"
        echo -e "${GREEN}✅ $file - Permissões corrigidas${NC}"
    else
        echo -e "${YELLOW}⚠️  $file - Arquivo não encontrado${NC}"
    fi
done

# Corrigir permissões dos diretórios
for dir in "${DIRECTORIES[@]}"; do
    if [ -d "$dir" ]; then
        chmod 755 "$dir"
        echo -e "${GREEN}✅ $dir - Permissões corrigidas${NC}"
    fi
done

# Corrigir permissões dos arquivos .sh em subdiretórios
find . -name "*.sh" -type f -exec chmod +x {} \;
echo -e "${GREEN}✅ Todos os arquivos .sh - Permissões corrigidas${NC}"

# Corrigir formatação dos arquivos (remover caracteres especiais)
echo -e "${YELLOW}🔧 Corrigindo formatação dos arquivos...${NC}"

# Lista de arquivos para corrigir formatação
FORMAT_FILES=(
    "install_ubuntu_22.04"
    "installubuntu"
    "install_simple.sh"
    "lib/_backend.sh"
    "lib/_frontend.sh"
    "lib/_system.sh"
    "lib/_inquiry.sh"
)

for file in "${FORMAT_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Remover caracteres especiais do Windows se existirem
        sed -i 's/\r$//' "$file" 2>/dev/null || true
        
        # Garantir que termina com quebra de linha
        if [ -s "$file" ] && [ "$(tail -c1 "$file" | wc -l)" -eq 0 ]; then
            echo "" >> "$file"
        fi
        
        echo -e "${GREEN}✅ $file - Formatação corrigida${NC}"
    fi
done

# Verificar encoding dos arquivos
echo -e "${YELLOW}🔍 Verificando encoding dos arquivos...${NC}"

for file in "${FORMAT_FILES[@]}"; do
    if [ -f "$file" ]; then
        # Verificar se o arquivo tem BOM (Byte Order Mark)
        if file "$file" | grep -q "UTF-8 Unicode (with BOM)"; then
            echo -e "${YELLOW}⚠️  $file - Contém BOM, removendo...${NC}"
            # Remover BOM se necessário
            sed -i '1s/^\xEF\xBB\xBF//' "$file" 2>/dev/null || true
        fi
    fi
done

# Verificar se os arquivos são executáveis
echo -e "${YELLOW}🔍 Verificando arquivos executáveis...${NC}"

for file in "${EXECUTABLE_FILES[@]}"; do
    if [ -f "$file" ] && [ -x "$file" ]; then
        echo -e "${GREEN}✅ $file - Executável${NC}"
    elif [ -f "$file" ]; then
        echo -e "${RED}❌ $file - Não é executável${NC}"
        chmod +x "$file"
        echo -e "${GREEN}✅ $file - Agora é executável${NC}"
    fi
done

# Verificar shebang nos arquivos
echo -e "${YELLOW}🔍 Verificando shebang nos arquivos...${NC}"

for file in "${EXECUTABLE_FILES[@]}"; do
    if [ -f "$file" ]; then
        if head -n1 "$file" | grep -q "^#!/bin/bash"; then
            echo -e "${GREEN}✅ $file - Shebang correto${NC}"
        else
            echo -e "${YELLOW}⚠️  $file - Shebang incorreto ou ausente${NC}"
            # Adicionar shebang se não existir
            if ! head -n1 "$file" | grep -q "^#!"; then
                sed -i '1i#!/bin/bash' "$file"
                echo -e "${GREEN}✅ $file - Shebang adicionado${NC}"
            fi
        fi
    fi
done

echo ""
echo -e "${GREEN}✅ Correção de permissões e formatação concluída!${NC}"
echo ""
echo -e "${YELLOW}💡 Agora você pode executar:${NC}"
echo "  - sudo ./install_simple.sh (recomendado)"
echo "  - sudo ./install_ubuntu_22.04"
echo "  - sudo ./installubuntu"
echo ""
echo -e "${YELLOW}🔧 Se ainda houver problemas, execute:${NC}"
echo "  - file install_simple.sh (verificar tipo de arquivo)"
echo "  - cat -A install_simple.sh | head -5 (verificar caracteres especiais)" 