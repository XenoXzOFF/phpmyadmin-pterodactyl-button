#!/bin/bash

# Fonction pour afficher des messages colorés
info() { echo -e "\e[32m[INFO]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

# 1. Mise en maintenance
php /var/www/pterodactyl/artisan down

# 2. Mise à jour des fichiers (votre logique actuelle)
cd /var/www/pterodactyl/resources/scripts/components/server/databases
rm -rf DatabaseRow.tsx
wget -q https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/DatabaseRow.tsx

cd /var/www/pterodactyl/public
rm -rf pma_redirect.html
wget -q https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/pma_redirect.html

# 3. Input domaine
echo -n "Entrez l'URL de votre phpMyAdmin : "
read pmalocation
sed -i "s|http:\/\/yourdomain.com\/phpmyadmin|$pmalocation|g" /var/www/pterodactyl/public/pma_redirect.html

# 4. Installation automatique de Node.js si nécessaire
if ! command -v npm &> /dev/null; then
    info "Node.js/npm non détecté. Installation en cours..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
    apt install -y nodejs > /dev/null 2>&1
    info "Node.js installé avec succès."
fi

# 5. Compilation
info "Compilation des assets..."
cd /var/www/pterodactyl
npm install > /dev/null 2>&1
npm run build:production > /dev/null 2>&1

# 6. Remise en ligne
php /var/www/pterodactyl/artisan up
info "Installation terminée avec succès !"