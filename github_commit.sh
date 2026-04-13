#!/bin/bash

# Script para commit e push no GitHub
# Autor: Lucas Clemente
# Suporta: apt (Debian/Ubuntu), zypper (openSUSE/SUSE)

detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

install_package() {
    local pkg=$1
    local pm=$(detect_package_manager)
    
    case $pm in
        apt)
            sudo apt-get update && sudo apt-get install -y "$pkg"
            ;;
        zypper)
            sudo zypper install -y "$pkg"
            ;;
        *)
            echo "Gerenciador de pacotes não suportado. Instale $pkg manualmente."
            return 1
            ;;
    esac
}

# Verificar se zenity está instalado
if ! command -v zenity &> /dev/null; then
    echo "Instalando zenity..."
    install_package zenity
fi

# Primeiro, selecionar o diretório
PROJETO_DIR=$(zenity --file-selection --directory --title="Selecione o diretório do projeto")
if [ $? -ne 0 ]; then
    exit 1
fi

# Depois obter os outros dados em uma tela
DADOS=$(zenity --forms --title="GitHub Commit" --text="Projeto: $PROJETO_DIR\n\nPreencha os dados:" \
    --add-entry="Usuário GitHub:" \
    --add-entry="Nome do repositório:" \
    --add-entry="Mensagem do commit:")

if [ $? -ne 0 ]; then
    exit 1
fi

# Separar os dados
USUARIO=$(echo "$DADOS" | cut -d'|' -f1)
REPO_NAME=$(echo "$DADOS" | cut -d'|' -f2)
COMMIT_MSG=$(echo "$DADOS" | cut -d'|' -f3)

# Validar campos obrigatórios
if [ -z "$USUARIO" ] || [ -z "$REPO_NAME" ] || [ -z "$PROJETO_DIR" ]; then
    zenity --error --text="Todos os campos são obrigatórios!"
    exit 1
fi

# Definir mensagem padrão se vazia
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="Initial commit"
fi

cd "$PROJETO_DIR"

# Verificar se é um repositório git
if [ ! -d ".git" ]; then
    if zenity --question --text="Este não é um repositório Git. Deseja inicializar?"; then
        git init
    else
        exit 1
    fi
fi

# Verificar se há arquivos para commit
if [ -z "$(git status --porcelain)" ]; then
    zenity --info --text="Não há alterações para commit."
    exit 0
fi

# Executar comandos git
(
echo "10"; echo "# Adicionando arquivos..."
git add .

echo "30"; echo "# Fazendo commit..."
git commit -m "$COMMIT_MSG"

echo "50"; echo "# Configurando branch main..."
git branch -M main

echo "70"; echo "# Configurando repositório remoto..."
git remote remove origin 2>/dev/null
git remote add origin "git@github.com:$USUARIO/$REPO_NAME.git"

echo "90"; echo "# Enviando para GitHub..."
git push -u origin main

echo "100"; echo "# Concluído!"
) | zenity --progress --title="Enviando para GitHub" --percentage=0 --auto-close

if [ $? -eq 0 ]; then
    zenity --info --text="Projeto enviado com sucesso para:\nhttps://github.com/$USUARIO/$REPO_NAME"
else
    zenity --error --text="Erro ao enviar projeto. Verifique suas credenciais SSH."
fi