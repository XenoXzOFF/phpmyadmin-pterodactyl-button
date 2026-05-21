#!/bin/bash

VERSION="1.2.0"
SCRIPT_NAME="phpmyadmin-pterodactyl-button"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

clear
echo -e "${BLUE}============================================"
echo -e "   ${SCRIPT_NAME} - Version ${VERSION}"
echo -e "   Auteur : XenoXz"
echo -e "============================================${NC}"
echo -e "Ce script va installer automatiquement le bouton"
echo -e "phpMyAdmin sur votre panel Pterodactyl."
echo -e ""
echo -e "${YELLOW}Informations :${NC}"
echo -e "- Modifie DatabaseRow.tsx"
echo -e "- Crée une redirection dans /public"
echo -e "- Recompile les assets du panel"
echo -e ""

read -p "Voulez-vous vraiment continuer ? (y/n) : " confirm
if [[ $confirm != [yY] ]]; then
    info "Installation annulée."
    exit 0
fi

info "Mise en maintenance du panel... - Le panel sera indisponible pendant l'installation. Veuillez patienter..."
php /var/www/pterodactyl/artisan down

info "Téléchargement des composants..."
cd /var/www/pterodactyl/resources/scripts/components/server/databases
wget -qO DatabaseRow.tsx https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/DatabaseRow.tsx

cd /var/www/pterodactyl/public
wget -qO pma_redirect.html https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/pma_redirect.html

echo -e "\n${BLUE}--- CONFIGURATION ---${NC}"
read -p "Entrez l'URL de votre phpMyAdmin (ex: https://pma.domaine.com) : " pmalocation
sed -i "s|http:\/\/yourdomain.com\/phpmyadmin|$pmalocation|g" /var/www/pterodactyl/public/pma_redirect.html

if ! command -v npm &> /dev/null; then
    info "Installation de Node.js (Version 20)..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt install -y nodejs > /dev/null 2>&1
fi

info "Compilation des assets (cela peut durer quelques minutes)..."
cd /var/www/pterodactyl
rm -rf node_modules
rm -rf public/build/*
npm install --legacy-peer-deps > /dev/null 2>&1
./node_modules/.bin/webpack --mode production > /dev/null 2>&1

php /var/www/pterodactyl/artisan up
success "Installation terminée avec succès !"
echo -e "${BLUE}Note :${NC} Si le bouton n'apparaît pas, faites un CTRL + F5 sur votre page de bases de données."