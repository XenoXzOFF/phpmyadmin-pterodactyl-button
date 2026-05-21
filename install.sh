#!/bin/bash

# Configuration
VERSION="1.7.0"
SCRIPT_NAME="Ptero-phpMyAdmin-Installer"

# Couleurs
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# Fonctions
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

# --- DIAGNOSTIC SYSTÈME ---
echo -e "${YELLOW}--- Vérification du système ---${NC}"
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
[ "$RAM_TOTAL" -lt 1500 ] && warn "RAM faible (${RAM_TOTAL}Mo)." || success "RAM OK (${RAM_TOTAL}Mo)."
command -v node &> /dev/null && success "Node.js est installé." || error "Node.js manquant."
command -v npm &> /dev/null && success "NPM est installé." || error "NPM manquant."
[ -d "/var/www/pterodactyl" ] && success "Répertoire Pterodactyl trouvé." || { error "Répertoire introuvable."; exit 1; }

echo -e "\n${YELLOW}Actions :${NC}"
echo -e "- Téléchargement des composants"
echo -e "- Configuration de l'URL"
echo -e "- Recompilation complète des assets"
echo -e ""

read -p "Voulez-vous continuer ? (y/n) : " confirm
[[ $confirm != [yY] ]] && { info "Annulé."; exit 0; }

# --- INSTALLATION ---
info "Mise en maintenance..."
php /var/www/pterodactyl/artisan down

info "Préparation des fichiers..."
rm -f /var/www/pterodactyl/resources/scripts/components/server/databases/DatabaseRow.tsx
rm -f /var/www/pterodactyl/public/pma_redirect.html

wget -qO /var/www/pterodactyl/resources/scripts/components/server/databases/DatabaseRow.tsx https://raw.githubusercontent.com/XenoXzOFF/phpmyadmin-pterodactyl-button/refs/heads/main/files/DatabaseRow.tsx
wget -qO /var/www/pterodactyl/public/pma_redirect.html https://raw.githubusercontent.com/XenoXzOFF/phpmyadmin-pterodactyl-button/refs/heads/main/files/pma_redirect.html

echo -e "\n${BLUE}--- CONFIGURATION ---${NC}"
read -p "URL phpMyAdmin (ex: https://pma.domaine.com) : " pmalocation
sed -i "s|http:\/\/yourdomain.com\/phpmyadmin|$pmalocation|g" /var/www/pterodactyl/public/pma_redirect.html

# Installation Node si nécessaire
if ! command -v npm &> /dev/null; then
    info "Installation de Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt install -y nodejs > /dev/null 2>&1
fi

info "Compilation en cours (cela peut prendre quelques minutes)..."
cd /var/www/pterodactyl
rm -rf node_modules
rm -rf public/build/*
npm install --legacy-peer-deps > /dev/null 2>&1
./node_modules/.bin/webpack --mode production > /dev/null 2>&1

php /var/www/pterodactyl/artisan up
success "Installation terminée avec succès !"