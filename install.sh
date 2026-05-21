#!/bin/bash

# Couleurs et style
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. Mise en maintenance
info "Mise en maintenance du panel..."
php /var/www/pterodactyl/artisan down

# 2. Téléchargement des fichiers
info "Téléchargement des fichiers..."
cd /var/www/pterodactyl/resources/scripts/components/server/databases
wget -qO DatabaseRow.tsx https://raw.githubusercontent.com/XenoXzOFF/phpmyadmin-pterodactyl-button/refs/heads/main/files/DatabaseRow.tsx

cd /var/www/pterodactyl/public
wget -qO pma_redirect.html https://raw.githubusercontent.com/XenoXzOFF/phpmyadmin-pterodactyl-button/refs/heads/main/files/pma_redirect.html

# 3. Input domaine
echo -e "\n${BLUE}--- CONFIGURATION ---${NC}"
read -p "Entrez l'URL de votre phpMyAdmin (ex: https://pma.domaine.com) : " pmalocation
sed -i "s|http:\/\/yourdomain.com\/phpmyadmin|$pmalocation|g" /var/www/pterodactyl/public/pma_redirect.html

# 4. Installation des dépendances (si nécessaire)
if ! command -v npm &> /dev/null; then
    info "Installation de Node.js/npm..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt install -y nodejs > /dev/null 2>&1
fi

# 5. Compilation forcée (Correction des erreurs ERESOLVE)
info "Compilation des assets (cela peut prendre du temps)..."
cd /var/www/pterodactyl

# Nettoyage
rm -rf node_modules
rm -rf public/build/*

# Installation avec legacy-peer-deps pour ignorer les conflits React
npm install --legacy-peer-deps > /dev/null 2>&1

# Build avec Webpack direct
if [ -f "./node_modules/.bin/webpack" ]; then
    ./node_modules/.bin/webpack --mode production > /dev/null 2>&1
else
    error "La compilation a échoué : Webpack introuvable."
    php /var/www/pterodactyl/artisan up
    exit 1
fi

# 6. Finalisation
php /var/www/pterodactyl/artisan up
success "phpMyAdmin est installé et le panel est prêt !"
info "N'oubliez pas de vider le cache de votre navigateur (Ctrl + F5) !"