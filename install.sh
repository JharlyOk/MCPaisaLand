#!/bin/bash

# ==============================================================================================
# EpicScript - Instalador para Linux (PaisaLand)
# ==============================================================================================

# --- CONFIGURACIÓN ---
# ¡IMPORTANTE! REEMPLAZA ESTOS LINKS POR LOS TUYOS DE DROPBOX
URL_LOW="https://www.dropbox.com/scl/fi/0uq96jnx7a3tsfwz79mrg/PC-Gama-Baja.zip?rlkey=oi5am56nw8aihcixj709ksgri&st=id22tog3&dl=0"
URL_HIGH="https://www.dropbox.com/scl/fi/mdqsni1k9ht8fuadv9kzd/PC-Gama-Alta.zip?rlkey=wgn6buj6qrnmxeqjsp03by4k5&st=wr6czevh&dl=0"

# Auto-corregir links de Dropbox (dl=0 -> dl=1)
URL_LOW=${URL_LOW//dl=0/dl=1}
URL_HIGH=${URL_HIGH//dl=0/dl=1}
MINECRAFT_DIR="$HOME/.minecraft"
TEMP_DIR="/tmp/PaisaLand_Installer"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Limpiar pantalla
clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}      PaisaLand - Instalador para Linux        ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# Verificar dependencias (unzip)
if ! command -v unzip &> /dev/null; then
    echo -e "${RED}[ERROR] 'unzip' no está instalado.${NC}"
    echo "Por favor instálalo (ej: sudo apt install unzip) y vuelve a intentar."
    exit 1
fi

# Menú de Selección
echo -e "Selecciona tu versión:"
echo -e "1) ${GREEN}PC Gama Baja${NC} (Optimizado - Mods esenciales)"
echo -e "2) ${YELLOW}PC Gama Alta${NC} (Experiencia completa + Shaders)"
echo ""
read -p ">> Ingresa opción [1 o 2]: " OPTION

TARGET_URL=""
if [ "$OPTION" == "1" ]; then
    TARGET_URL="$URL_LOW"
    echo -e "\n>> Modo seleccionado: ${GREEN}GAMA BAJA${NC}"
elif [ "$OPTION" == "2" ]; then
    TARGET_URL="$URL_HIGH"
    echo -e "\n>> Modo seleccionado: ${YELLOW}GAMA ALTA${NC}"
else
    echo -e "\n${RED}Opción inválida. Saliendo...${NC}"
    exit 1
fi

# Validación de URL
if [[ "$TARGET_URL" == *"URL_"* ]] || [[ -z "$TARGET_URL" ]]; then
    echo -e "${RED}[ERROR] URL de descarga no configurada por el administrador.${NC}"
    echo "Edita el archivo 'install.sh' y pon los links correctos."
    exit 1
fi

# Verificar carpeta de Minecraft
if [ ! -d "$MINECRAFT_DIR" ]; then
    echo -e "${RED}[ERROR] No se encontró la carpeta .minecraft en: $MINECRAFT_DIR${NC}"
    echo "¿Has ejecutado Minecraft al menos una vez?"
    exit 1
fi

# --- 1. BACKUP ---
echo -e "\n${BLUE}[1/3] Creando Backup...${NC}"
BACKUP_DIR="$HOME/Desktop/PaisaLand_Backup_$(date +%Y%m%d_%H%M%S)"
# Intentar crear en Desktop, si no existe Desktop, crear en Home
if [ ! -d "$HOME/Desktop" ]; then BACKUP_DIR="$HOME/PaisaLand_Backup_$(date +%Y%m%d_%H%M%S)"; fi

mkdir -p "$BACKUP_DIR"
for item in mods config shaderpacks resourcepacks emotes options.txt servers.dat; do
    if [ -e "$MINECRAFT_DIR/$item" ]; then
        cp -r "$MINECRAFT_DIR/$item" "$BACKUP_DIR/"
    fi
done
echo -e "Backup guardado en: $BACKUP_DIR"

# --- 2. LIMPIEZA ---
echo -e "${YELLOW}Limpiando archivos antiguos...${NC}"
rm -rf "$MINECRAFT_DIR/mods" "$MINECRAFT_DIR/config" "$MINECRAFT_DIR/shaderpacks"

# --- 3. DESCARGA ---
echo -e "\n${BLUE}[2/3] Descargando Modpack...${NC}"
mkdir -p "$TEMP_DIR"
ZIP_FILE="$TEMP_DIR/modpack.zip"

if command -v curl &> /dev/null; then
    curl -L "$TARGET_URL" -o "$ZIP_FILE" --progress-bar
elif command -v wget &> /dev/null; then
    wget -q --show-progress "$TARGET_URL" -O "$ZIP_FILE"
else
    echo -e "${RED}[ERROR] No se encontró ni 'curl' ni 'wget' para descargar.${NC}"
    exit 1
fi

# --- 4. INSTALACIÓN ---
echo -e "\n${BLUE}[3/3] Instalando y Configurando...${NC}"
unzip -q -o "$ZIP_FILE" -d "$TEMP_DIR/extracted"

# Lógica inteligente para mover archivos (si el zip tiene carpeta raíz o no)
SOURCE_DIR="$TEMP_DIR/extracted"
# Contar carpetas visibles dentro de extracted
DIR_COUNT=$(find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l)
FILE_COUNT=$(find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 -type f | wc -l)

# Si solo hay 1 carpeta y 0 archivos, asumimos que esa carpeta contiene los mods
if [ "$DIR_COUNT" -eq 1 ] && [ "$FILE_COUNT" -eq 0 ]; then
    SINGLE_DIR=$(find "$SOURCE_DIR" -maxdepth 1 -mindepth 1 -type d)
    echo "Detectada carpeta contenedora: $(basename "$SINGLE_DIR")"
    SOURCE_DIR="$SINGLE_DIR"
fi

echo "Copiando archivos..."
cp -r "$SOURCE_DIR/"* "$MINECRAFT_DIR/"

# --- FINALIZAR ---
rm -rf "$TEMP_DIR"
echo -e "\n${GREEN}===============================================${NC}"
echo -e "${GREEN}      ¡INSTALACIÓN COMPLETADA!                 ${NC}"
echo -e "${GREEN}===============================================${NC}"
echo "Ya puedes abrir tu Minecraft Launcher y disfrutar de PaisaLand."
