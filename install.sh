#!/bin/bash

# Script de configuração do GitHub
# Autor: Lucas Clemente
# Funcionalidades: Instala Git, configura usuário, gera chave SSH, cria atalho de桌面包

set -o pipefail

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
    
    if [ "$pm" = "unknown" ]; then
        zenity --error --text="Gerenciador de pacotes não suportado.\nInstale $pkg manualmente e tente novamente."
        return 1
    fi
    
    (
    echo "0"; echo "# Atualizando lista de pacotes..."
    if [ "$pm" = "apt" ]; then
        sudo apt-get update -qq
        echo "50"; echo "# Instalando $pkg..."
        sudo apt-get install -y -qq "$pkg"
    elif [ "$pm" = "zypper" ]; then
        echo "50"; echo "# Instalando $pkg..."
        sudo zypper install -y -q "$pkg"
    fi
    echo "100"; echo "# Concluído"
    ) | zenity --progress --title="Instalando $pkg" --percentage=0 --auto-close
}

check_install_package() {
    local pkg=$1
    if ! command -v "$pkg" &> /dev/null; then
        if zenity --question --text="$pkg não está instalado.\nDeseja instalar agora?"; then
            install_package "$pkg"
            return $?
        else
            return 1
        fi
    fi
    return 0
}

show_progress() {
    local title=$1
    shift
    local commands=("$@")
    local total=${#commands[@]}
    local current=0
    
    (
    for cmd in "${commands[@]}"; do
        current=$((current + 1))
        percent=$((current * 100 / total))
        echo "$percent"; echo "# $cmd"
        sleep 0.5
    done
    ) | zenity --progress --title="$title" --percentage=0 --auto-close
}

check_git_installed() {
    if ! command -v git &> /dev/null; then
        if zenity --question --text="Git não está instalado.\nDeseja instalar agora?"; then
            install_package "git"
            return $?
        else
            return 1
        fi
    fi
    return 0
}

check_zenity_installed() {
    if ! command -v zenity &> /dev/null; then
        if zenity --question --text="zenity não está instalado (necessário para a interface).\nDeseja instalar agora?"; then
            install_package "zenity"
            return $?
        else
            zenity --error --text="zenity é necessário para este script."
            exit 1
        fi
    fi
    return 0
}

get_user_info() {
    local current_name=$(git config --global user.name 2>/dev/null || echo "")
    local current_email=$(git config --global user.email 2>/dev/null || echo "")
    
    DADOS=$(zenity --forms --title="Configuração GitHub" --text="Preencha seus dados:" \
        --add-entry="Nome (para commits):" \
        --add-entry="Email:" \
        --add-entry="Nome do repositório (opcional):")
    
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    GIT_NAME=$(echo "$DADOS" | cut -d'|' -f1)
    GIT_EMAIL=$(echo "$DADOS" | cut -d'|' -f2)
    REPO_NAME=$(echo "$DADOS" | cut -d'|' -f3)
    
    if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
        zenity --error --text="Nome e email são obrigatórios!"
        return 1
    fi
    
    GITHUB_USER=$(zenity --entry --title="Usuário GitHub" --text="Digite seu usuário do GitHub (ou deixe em branco para usar '$GIT_NAME'):" --entry-text="$GIT_NAME")
    
    if [ -z "$GITHUB_USER" ]; then
        GITHUB_USER="$GIT_NAME"
    fi
}

configure_git_identity() {
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    zenity --info --text="Configuração Git concluída:\nNome: $GIT_NAME\nEmail: $GIT_EMAIL"
}

check_generate_ssh_key() {
    local key_path="$HOME/.ssh/id_ed25519"
    
    if [ -f "$key_path" ]; then
        if zenity --question --text="Já existe uma chave SSH em $key_path\nDeseja sobrescrever?"; then
            generate_ssh_key
        else
            use_existing_ssh_key
        fi
    else
        generate_ssh_key
    fi
}

generate_ssh_key() {
    (
    echo "10"; echo "# Gerando chave SSH..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -N "" -f "$HOME/.ssh/id_ed25519"
    echo "100"; echo "# Chave gerada"
    ) | zenity --progress --title="Chave SSH" --percentage=0 --auto-close
    
    setup_ssh_agent
}

use_existing_ssh_key() {
    setup_ssh_agent
}

setup_ssh_agent() {
    eval "$(ssh-agent -s)" 2>/dev/null || true
    ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
    
    show_public_key
}

show_public_key() {
    local pub_key=$(cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null)
    
    if [ -n "$pub_key" ]; then
        zenity --info --text="Chave pública gerada!\n\nCopie a chave abaixo e adicione no GitHub:\nhttps://github.com/settings/keys\n\n$pub_key"
    else
        zenity --error --text="Erro ao ler chave pública."
        return 1
    fi
    
    if zenity --question --text="Já adicionou a chave no GitHub?\nClique em 'Sim' para testar a conexão."; then
        test_ssh_connection
    fi
}

test_ssh_connection() {
    local result=$(ssh -T git@github.com 2>&1)
    if echo "$result" | grep -q "successfully authenticated"; then
        zenity --info --text="Conexão com GitHub OK!\n\n$result"
        return 0
    else
        zenity --error --text="Erro na conexão com GitHub:\n$result"
        return 1
    fi
}

clone_repository() {
    if [ -n "$REPO_NAME" ]; then
        local target_dir=$(zenity --file-selection --directory --title="Selecione onde salvar o repositório")
        
        if [ -n "$target_dir" ]; then
            (
            echo "10"; echo "# Clonando repositório..."
            git clone "git@github.com:$GITHUB_USER/$REPO_NAME.git" "$target_dir/$REPO_NAME"
            echo "100"; echo "# Concluído"
            ) | zenity --progress --title="Clonando repositório" --percentage=0 --auto-close
            
            zenity --info --text="Repositório clonado em:\n$target_dir/$REPO_NAME"
        fi
    fi
}

create_desktop_shortcut() {
    local app_dir="$HOME/Documentos/.Apps/Github-commited"
    local desktop_file="$HOME/.local/share/applications/github-committed.desktop"
    
    mkdir -p "$app_dir"
    
    if [ -f "github_commit.sh" ]; then
        cp github_commit.sh "$app_dir"
    fi
    
    if [ -f "icon.png" ]; then
        cp icon.png "$app_dir"
    fi
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Name=Github Committed
Comment=Realiza commits de uma determinada pasta
Exec=bash $app_dir/github_commit.sh
Icon=$app_dir/icon.png
Terminal=false
Type=Application
Categories=Development;
StartupNotify=true
EOF
    
    chmod +x "$desktop_file"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    
    zenity --info --text="Atalho criado com sucesso!\nEstá disponível no menu de桌面包."
}

main() {
    check_zenity_installed || exit 1
    
    check_git_installed || exit 1
    
    while ! get_user_info; do
        if ! zenity --question --text="Dados inválidos. Tentar novamente?"; then
            exit 1
        fi
    done
    
    configure_git_identity
    
    check_generate_ssh_key
    
    clone_repository
    
    create_desktop_shortcut
    
    zenity --info --text="Configuração concluída!\n\nResumo:\n- Git configurado\n- Chave SSH configurada\n- Atalho criado"
}

main "$@"