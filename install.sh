#!/bin/bash

VERSION="1.3.0"
SCRIPT_NAME="phpmyadmin-pterodactyl-button"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

clear
echo -e "${BLUE}============================================"
echo -e "   ${SCRIPT_NAME} - Version ${VERSION}"
echo -e "   Machine : $(hostname)"
echo -e "   OS      : $(lsb_release -d | cut -f2)"
echo -e "============================================${NC}"

echo -e "${YELLOW}--- Vérification du système ---${NC}"

RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
if [ "$RAM_TOTAL" -lt 1500 ]; then
    warn "Mémoire faible détectée (${RAM_TOTAL}Mo). La compilation peut échouer."
else
    success "Mémoire suffisante (${RAM_TOTAL}Mo)."
fi

if command -v node &> /dev/null; then
    success "Node.js $(node -v) est installé."
else
    error "Node.js n'est pas installé."
fi

if command -v npm &> /dev/null; then
    success "NPM $(npm -v) est installé."
else
    error "NPM n'est pas installé."
fi

if [ -d "/var/www/pterodactyl" ]; then
    success "Répertoire Pterodactyl trouvé."
else
    error "Répertoire /var/www/pterodactyl introuvable. Installation impossible."
    exit 1
fi

echo -e "\n${YELLOW}Informations :${NC}"
echo -e "- Modifie DatabaseRow.tsx"
echo -e "- Crée une redirection pma_redirect.html"
echo -e "- Recompile les assets"
echo -e ""

read -p "Voulez-vous lancer l'installation ? (y/n) : " confirm
if [[ $confirm != [yY] ]]; then
    info "Installation annulée."
    exit 0
fi

info "Mise en maintenance..."
php /var/www/pterodactyl/artisan down

info "Téléchargement des composants..."
cd /var/www/pterodactyl/resources/scripts/components/server/databases
wget -qO DatabaseRow.tsx https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/DatabaseRow.tsx

cd /var/www/pterodactyl/public
wget -qO pma_redirect.html https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/pma_redirect.html

echo -e "\n${BLUE}--- CONFIGURATION ---${NC}"
read -p "URL phpMyAdmin (ex: https://pma.domaine.com) : " pmalocation
sed -i "s|http:\/\/yourdomain.com\/phpmyadmin|$pmalocation|g" /var/www/pterodactyl/public/pma_redirect.html

if ! command -v npm &> /dev/null; then
    info "Installation de Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt install -y nodejs > /dev/null 2>&1
fi

info "Compilation en cours (attendez)..."
cd /var/www/pterodactyl
rm -rf node_modules
rm -rf public/build/*
npm install --legacy-peer-deps > /dev/null 2>&1
./node_modules/.bin/webpack --mode production > /dev/null 2>&1

php /var/www/pterodactyl/artisan up
success "Installation terminée !"