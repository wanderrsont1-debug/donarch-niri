# CachyOS / Arch Linux Niri Environment Autoinstall

Este repositório contém um script de instalação automatizada e os dotfiles para recriar o ambiente atual de desktop baseado no compositor **Niri** e no **DankMaterialShell (dms-shell)**, incluindo todas as configurações de terminal, visualizador de áudio, fontes e temas de display manager.

## 📋 Estrutura do Repositório

*   `install.sh`: Script principal interativo para instalação e restauração completa.
*   `packages.txt`: Backup contendo todos os pacotes explicitamente instalados no sistema de origem (gerado pelo backup local para fins de referência).
*   `dotfiles/`: Arquivos de configuração do usuário:
    *   `niri/`: Configurações do compositor Niri (Wayland).
    *   `DankMaterialShell/`: Configuração da barra e componentes do shell desktop.
    *   `alacritty/` & `ghostty/`: Configurações de cores e layout dos emuladores de terminal.
    *   `fuzzel/`: Menu de aplicativos e launcher.
    *   `cava/`: Visualizador de espectro de áudio.
    *   `micro/`: Configurações do editor de texto de terminal.
    *   `fish/`: Configurações do terminal fish.
    *   `environment.d/`: Definições de variáveis de ambiente do usuário.
    *   `.bashrc`, `.zshrc`, `.bash_profile`, `.Xresources`.
*   `system/`: Configurações do display manager SDDM.

## 🚀 Como usar em uma instalação limpa (Arch Linux / CachyOS sem desktop)

Em um sistema Arch recém-instalado (apenas a base com rede configurada):

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/SEU-USUARIO/NOME-DO-REPO.git
    cd NOME-DO-REPO
    ```

2.  **Execute o script de instalação:**
    ```bash
    ./install.sh
    ```

O script perguntará passo a passo o que você deseja fazer:
*   Adicionar os repositórios oficiais e otimizados do CachyOS.
*   Instalar um AUR Helper (paru-bin) caso não tenha.
*   Instalar os pacotes essenciais e curados do ambiente (Niri, DMS, áudio, etc.).
*   Copiar todos os arquivos de configuração (dotfiles) para o seu usuário.
*   Instalar e configurar o tema de SDDM **SilentSDDM** (com o vídeo configurado).
*   Habilitar os serviços essenciais (SDDM, NetworkManager, Bluetooth).

## 🛠️ Como atualizar este repositório com suas novas configurações

Caso você faça alterações no seu sistema e queira salvar as novas configurações neste repositório:

Execute o script de backup local na pasta do projeto:
```bash
bash backup_local.sh
```
Depois disso, basta commitar e enviar as alterações para o seu GitHub/GitLab:
```bash
git add .
git commit -m "update configs and package list"
git push
```
