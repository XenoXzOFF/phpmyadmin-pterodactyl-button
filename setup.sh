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
cd /var/www/pterodactyl

info "Vérification des dépendances..."
# On force l'utilisation du gestionnaire de paquets
if [ -f "/usr/bin/npm" ]; then
    /usr/bin/npm install
    /usr/bin/npm run build:production
elif [ -f "/usr/local/bin/yarn" ]; then
    /usr/local/bin/yarn install
    /usr/local/bin/yarn run build:production
else
    error "Ni npm ni yarn n'ont été trouvés dans /usr/bin/ ou /usr/local/bin/."
    exit 1
fi

# 5. Remise en ligne
php /var/www/pterodactyl/artisan up
info "phpMyAdmin successfully installed and panel rebuilt."