#!/usr/bin/env bash
# Instalador Unificado de Ambiente Niri — Arch Linux / Fedora
# Melhorias baseadas no donarch (GitLab):
#   - checks.sh dedicado (detecção de distro, AUR helper, pacotes base)
#   - Backup automático de ~/.config antes dos dotfiles
#   - Seleção interativa de apps opcionais
#   - detect_user() para suporte correto a sudo

set -e          # Interrompe imediatamente se qualquer comando falhar
set -o pipefail # Propaga falhas em pipes

# Obter diretório do repositório
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source das bibliotecas modulares
source "$REPO_DIR/lib/utils.sh"
source "$REPO_DIR/lib/checks.sh"
source "$REPO_DIR/lib/packages.sh"
source "$REPO_DIR/lib/dotfiles.sh"
source "$REPO_DIR/lib/greeter.sh"

# ─────────────────────────────────────────────────────────────
# Tela de boas-vindas
# ─────────────────────────────────────────────────────────────
show_welcome() {
    clear
    echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     Instalador Unificado de Ambiente (Niri)      ║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║  Suporta: Arch Linux / CachyOS / Fedora          ║${NC}"
    echo -e "${CYAN}║  Display Managers: SDDM (Silent) ou greetd       ║${NC}"
    echo -e "${CYAN}║  Shell: DankMaterialShell (dms-shell)             ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    if ! prompt_yes_no "Deseja continuar com a instalação?" "S"; then
        log_info "Instalação cancelada pelo usuário."
        exit 0
    fi
    echo ""
}

# ─────────────────────────────────────────────────────────────
# Seleção do Display Manager
# ─────────────────────────────────────────────────────────────
select_display_manager() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${YELLOW}Selecione o gerenciador de login (Display Manager):${NC}"
    echo -e "  1) SDDM (com tema Silent)"
    echo -e "  2) greetd (com tuigreet)"
    echo -e "  3) Nenhum (não gerenciar Display Manager)"
    echo -e "${BLUE}===============================================${NC}"

    while true; do
        read -p "Opção [1-3] (padrão: 1): " dm_choice
        dm_choice=${dm_choice:-1}
        if [[ "$dm_choice" =~ ^[1-3]$ ]]; then
            break
        else
            log_warn "Opção inválida. Por favor, selecione 1, 2 ou 3."
        fi
    done
    echo ""
}

# ─────────────────────────────────────────────────────────────
# Confirmação de backup
# ─────────────────────────────────────────────────────────────
confirm_backup() {
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${YELLOW}Backup de Configurações${NC}"
    echo -e "${BLUE}===============================================${NC}"
    log_info "Recomendamos fazer backup do seu ~/.config antes de implantar dotfiles."
    echo ""

    if prompt_yes_no "Deseja criar backup de ~/.config agora? (Recomendado)" "S"; then
        backup_existing_configs
    else
        log_warn "Backup ignorado — configurações existentes podem ser sobrescritas."
    fi
    echo ""
}

# ─────────────────────────────────────────────────────────────
# Fluxo de instalação principal
# ─────────────────────────────────────────────────────────────
main() {
    # 0. Tela de boas-vindas
    show_welcome

    # 1. Verificações de sistema (distro, root, rede, AUR helper, pacotes base)
    run_all_checks || { log_error "Verificações de sistema falharam. Abortando."; exit 1; }

    # 2. Selecionar Display Manager
    select_display_manager

    # 3. Backup de configurações existentes
    confirm_backup

    # 4. Instalar pacotes baseados na distribuição
    # Subshell evita que set -e aborte o script se um pacote AUR falhar
    if [ "$DISTRO" = "fedora" ]; then
        ( install_fedora_packages "$dm_choice" ) || log_warn "Alguns pacotes podem não ter sido instalados."
    else
        ( install_arch_packages "$dm_choice" "$REPO_DIR" ) || log_warn "Alguns pacotes podem não ter sido instalados."
    fi

    # 5. Implantar dotfiles
    if prompt_yes_no "Deseja implantar os arquivos de configuração (dotfiles) via links simbólicos?" "S"; then
        deploy_dotfiles "$REPO_DIR"
    fi

    # 6. Configurar Display Manager
    configure_display_manager "$dm_choice" "$REPO_DIR"

    # 7. Habilitar serviços do sistema
    enable_systemd_services "$dm_choice"

    # 8. Verificar se o Display Manager está pronto antes de reiniciar
    local dm_verified=true
    if [ "$dm_choice" != "3" ]; then
        verify_display_manager "$dm_choice" "$REPO_DIR" || dm_verified=false
    fi

    # ─────────────────────────────────────────────────────────
    # Conclusão
    # ─────────────────────────────────────────────────────────
    echo ""
    if $dm_verified; then
        echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           Instalação Concluída com Sucesso!      ║${NC}"
        echo -e "${BLUE}╠══════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║  Próximos passos:                                ║${NC}"
        echo -e "${CYAN}║  1. Reinicie o sistema para ativar o DM          ║${NC}"
        echo -e "${CYAN}║  2. Faça login e selecione a sessão Niri         ║${NC}"
        echo -e "${CYAN}║  3. O ambiente DMS iniciará automaticamente      ║${NC}"
        echo -e "${BLUE}╠══════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║  Teclas principais do Niri:                      ║${NC}"
        echo -e "${YELLOW}║  Super+T   → Terminal (Ghostty)                  ║${NC}"
        echo -e "${YELLOW}║  Super+Q   → Fechar janela                       ║${NC}"
        echo -e "${YELLOW}║  Super+F   → Gerenciador de arquivos             ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║     Instalação Concluída — COM AVISOS ⚠         ║${NC}"
        echo -e "${BLUE}╠══════════════════════════════════════════════════╣${NC}"
        echo -e "${RED}║  A verificação do Display Manager encontrou     ║${NC}"
        echo -e "${RED}║  problemas. Revise os erros acima antes de      ║${NC}"
        echo -e "${RED}║  reiniciar para evitar ficar preso no TTY.      ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    fi
    echo ""

    if $dm_verified; then
        log_warn "Recomenda-se reiniciar o computador para aplicar todas as configurações."
        echo ""
        if prompt_yes_no "Deseja reiniciar o sistema agora?" "N"; then
            log_info "Reiniciando em 3 segundos..."
            sleep 3
            sudo reboot
        fi
    else
        log_error "NÃO é recomendado reiniciar com problemas no Display Manager."
        log_info "Corrija os erros acima e depois execute:"
        log_info "  sudo systemctl enable sddm.service"
        log_info "  sudo systemctl set-default graphical.target"
        log_info "  sudo reboot"
    fi
}

main
