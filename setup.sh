#!/bin/bash

# Fonction pour afficher des messages colorés
info() { echo -e "\e[32m[INFO]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; }

# 1. Mise en maintenance
php /var/www/pterodactyl/artisan down

# 2. Mise à jour des fichiers
cd /var/www/pterodactyl/resources/scripts/components/server/databases
rm -rf DatabaseRow.tsx
wget -q https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/DatabaseRow.tsx

cd /var/www/pterodactyl/public
rm -rf pma_redirect.html
wget -q https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/pma_redirect.html

# 3. Input pour le domaine avec interface claire
echo "--------------------------------------------------------"
echo "  CONFIGURATION DE PHPMYADMIN"
echo "--------------------------------------------------------"
echo -n "Entrez l'URL de votre phpMyAdmin (ex: https://pma.domaine.com) : "
read pmalocation

if [ -z "$pmalocation" ]; then
    error "Aucun domaine saisi. Annulation."
    php /var/www/pterodactyl/artisan up
    exit 1
fi

sed -i "s|http:\/\/yourdomain.com\/phpmyadmin|$pmalocation|g" /var/www/pterodactyl/public/pma_redirect.html
info "Domaine configuré : $pmalocation"

# 4. Compilation avec chemin absolu pour éviter l'erreur "run"
info "Compilation des assets... (cela peut prendre quelques minutes)"
cd /var/www/pterodactyl
# On force l'utilisation du binaire yarn ou npm
if command -v yarn &> /dev/null; then
    yarn install && yarn run build:production
else
    npm install && npm run build:production
fi

# 5. Remise en ligne
php /var/www/pterodactyl/artisan up
info "phpMyAdmin successfully installed and panel rebuilt."