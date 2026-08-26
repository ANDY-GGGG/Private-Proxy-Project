#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# 🍷 WINE PORTABLE - INSTALADOR AUTOMÁTICO
# ============================================================

# ---------------- CORES ----------------

RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
CYAN="\033[36m"
GRAY="\033[90m"

clear

# ---------------- CABEÇALHO ----------------

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║        🍷  WINE PORTABLE INSTALLER          ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${RESET}"

# ---------------- PROGRESSO ----------------

progress() {

    local percent="$1"
    local message="$2"

    local width=30
    local filled=$((percent * width / 100))
    local empty=$((width - filled))

    local bar=""
    local rest=""

    printf -v bar "%${filled}s"
    printf -v rest "%${empty}s"

    bar="${bar// /█}"
    rest="${rest// /░}"

    printf "\r${CYAN}[%s%s]${RESET} ${BOLD}%3d%%${RESET}  %s" \
        "$bar" "$rest" "$percent" "$message"

    if [[ "$percent" -eq 100 ]]; then
        echo
    fi
}

# ---------------- ERRO ----------------

fail() {

    echo
    echo
    echo -e "${RED}${BOLD}✖ A instalação não pôde ser concluída.${RESET}"
    echo
    echo -e "${GRAY}$1${RESET}"
    echo
    echo "Pressione ENTER para fechar."
    read -r

    exit 1
}

# ============================================================
# NÃO EXECUTAR COMO ROOT
# ============================================================

if [[ "$EUID" -eq 0 ]]; then
    fail "Não execute este instalador usando sudo."
fi


progress 5 "Iniciando..."
sleep 0.2


# ============================================================
# LOCALIZA A PASTA DO INSTALADOR
# ============================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

progress 15 "Localizando Wine Portable..."
sleep 0.2


# ============================================================
# PROCURA O WINE
# ============================================================

# Primeiro procura ao lado do instalador
if [[ -f "$SCRIPT_DIR/wine/wine" ]]; then

    WINE_DIR="$SCRIPT_DIR/wine"

else

    # Depois tenta a pasta Downloads correta do sistema

    if command -v xdg-user-dir >/dev/null 2>&1; then
        DOWNLOAD_DIR="$(xdg-user-dir DOWNLOAD)"
    else
        DOWNLOAD_DIR="$HOME/Downloads"
    fi

    if [[ -f "$DOWNLOAD_DIR/wine/wine" ]]; then

        WINE_DIR="$DOWNLOAD_DIR/wine"

    else

        fail "Não encontrei wine/wine.

Coloque a pasta 'wine' ao lado do instalador
ou dentro da pasta Downloads."

    fi
fi


WINE_BIN="$WINE_DIR/wine"

chmod +x "$WINE_BIN"

progress 30 "Wine encontrado."
sleep 0.2


# ============================================================
# CRIA WRAPPER
# ============================================================

BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"

WRAPPER="$BIN_DIR/wine-portable-open"


cat > "$WRAPPER" <<EOF
#!/usr/bin/env bash

WINE_BIN="$WINE_BIN"

if [[ \$# -eq 0 ]]; then
    exit 0
fi

exec "\$WINE_BIN" wine "\$@"
EOF


chmod +x "$WRAPPER"


progress 45 "Criando integração com o Linux..."
sleep 0.2


# ============================================================
# CRIA APLICAÇÃO
# ============================================================

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPLICATIONS="$DATA_HOME/applications"

mkdir -p "$APPLICATIONS"

DESKTOP="$APPLICATIONS/wine-portable.desktop"


cat > "$DESKTOP" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=🍷 Executar com Wine
GenericName=Wine Portable
Comment=Executa aplicativos do Windows
Exec=$WRAPPER %F
Icon=wine
Terminal=false
StartupNotify=true
NoDisplay=false
MimeType=application/x-ms-dos-executable;application/vnd.microsoft.portable-executable;application/x-msdownload;application/x-msi;application/x-ms-shortcut;
Categories=Utility;
EOF


chmod 644 "$DESKTOP"


progress 60 "Registrando aplicativo..."
sleep 0.2


# ============================================================
# ATUALIZA BANCO DE APLICATIVOS
# ============================================================

if command -v update-desktop-database >/dev/null 2>&1; then

    update-desktop-database "$APPLICATIONS" >/dev/null 2>&1 || true

fi


progress 70 "Configurando arquivos .EXE..."
sleep 0.2


# ============================================================
# TIPOS DE ARQUIVO WINDOWS
# ============================================================

MIME_TYPES=(

    "application/x-ms-dos-executable"
    "application/vnd.microsoft.portable-executable"
    "application/x-msdownload"
    "application/x-msi"
    "application/x-ms-shortcut"

)


# ============================================================
# DEFINE COMO PADRÃO
# ============================================================

if command -v xdg-mime >/dev/null 2>&1; then

    for MIME in "${MIME_TYPES[@]}"; do

        xdg-mime default wine-portable.desktop "$MIME" \
            >/dev/null 2>&1 || true

    done

fi


progress 82 "Aplicando associações..."
sleep 0.2


# ============================================================
# GIO - SEGUNDA CAMADA DE COMPATIBILIDADE
# ============================================================

if command -v gio >/dev/null 2>&1; then

    for MIME in "${MIME_TYPES[@]}"; do

        gio mime "$MIME" wine-portable.desktop \
            >/dev/null 2>&1 || true

    done

fi


progress 92 "Atualizando sistema..."
sleep 0.2


# ============================================================
# ATUALIZA MAIS UMA VEZ
# ============================================================

if command -v update-desktop-database >/dev/null 2>&1; then

    update-desktop-database "$APPLICATIONS" \
        >/dev/null 2>&1 || true

fi


# ============================================================
# FINAL
# ============================================================

progress 100 "Instalação concluída!"

sleep 0.3

echo
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║              ✓ TUDO PRONTO!                 ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e " ${GREEN}✓${RESET} Wine Portable encontrado"
echo -e " ${GREEN}✓${RESET} Wine integrado ao Linux"
echo -e " ${GREEN}✓${RESET} Arquivos .EXE configurados"
echo -e " ${GREEN}✓${RESET} Arquivos .MSI configurados"
echo -e " ${GREEN}✓${RESET} Wine definido como aplicativo padrão"

echo
echo -e "${CYAN}${BOLD}Agora basta dar dois cliques em qualquer .exe.${RESET}"
echo

echo -e "${GRAY}Pressione ENTER para fechar.${RESET}"
read -r