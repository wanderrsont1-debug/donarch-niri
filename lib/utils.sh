#!/usr/bin/env bash
# Utilitários gerais do instalador

# Cores para mensagens
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1" >&2
}

# Prompt de Sim ou Não
prompt_yes_no() {
    local prompt_msg="$1"
    local default_val="$2" # "S" ou "N"
    local reply

    if [ "$default_val" = "S" ]; then
        prompt_msg="$prompt_msg [S/n]: "
    else
        prompt_msg="$prompt_msg [s/N]: "
    fi

    read -p "$prompt_msg" reply
    reply=${reply:-$default_val}

    if [[ "$reply" =~ ^[SsYy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Detectar o usuário real (mesmo quando executado via sudo)
# Inspirado no donarch — garante que dotfiles sejam do usuário correto
detect_user() {
    if [ -n "${SUDO_USER:-}" ]; then
        echo "$SUDO_USER"
    else
        echo "$USER"
    fi
}

# Obter o diretório home do usuário real
get_user_home() {
    local user
    user=$(detect_user)
    getent passwd "$user" | cut -d: -f6
}

# Fazer backup completo de ~/.config com timestamp antes de implantar dotfiles
# Inspirado no donarch — evita perda de configurações existentes
backup_existing_configs() {
    local user_home
    user_home=$(get_user_home)
    local config_dir="$user_home/.config"
    local backup_dir="$user_home/.config.backup-$(date +%Y%m%d_%H%M%S)"

    if [ -d "$config_dir" ]; then
        log_info "Criando backup completo de ~/.config em: $backup_dir"
        cp -a "$config_dir" "$backup_dir"
        log_success "Backup criado em: $backup_dir"
        return 0
    else
        log_warn "Diretório ~/.config não encontrado, backup ignorado."
        return 0
    fi
}

# Verificação de conectividade com a internet
# Testa contra múltiplos alvos para evitar falso negativo por bloqueio de um servidor
check_internet() {
    log_info "Verificando conectividade com a internet..."
    local targets=("archlinux.org" "fedoraproject.org" "1.1.1.1")
    for target in "${targets[@]}"; do
        if curl -s --max-time 5 --head "https://${target}" > /dev/null 2>&1; then
            log_success "Conexão com a internet confirmada."
            return 0
        fi
    done
    log_error "Sem conexão com a internet. Verifique sua rede antes de continuar."
    log_error "Em ambientes mínimos sem desktop, execute: sudo systemctl start NetworkManager"
    return 1
}
