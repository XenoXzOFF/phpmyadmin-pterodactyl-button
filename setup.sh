#!/bin/bash

# Mettre le panneau en mode maintenance
php /var/www/pterodactyl/artisan down

# Mise à jour des fichiers de base de données
cd /var/www/pterodactyl/resources/scripts/components/server/databases
rm -rf DatabaseRow.tsx
wget https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/DatabaseRow.tsx

# Mise à jour de la redirection
cd /var/www/pterodactyl/public
rm -rf pma_redirect.html
wget https://raw.githubusercontent.com/finnie2006/PteroFreeStuffinstaller/main/resources/phpmyadmin/pma_redirect.html

# Configuration de l'URL phpMyAdmin
if [ -z "$pmalocation" ]; then
    echo " "
    echo 'Where is phpMyAdmin located? Make sure to have "http://" or "https://" !'
    echo "For example: https://pma.yourdomain.com"
    echo " "
    read -r pmalocation
    
    # Remplacement de l'URL dans le fichier
    sed -i "s|http:\/\/yourdomain.com\/phpmyadmin|$pmalocation|g" /var/www/pterodactyl/public/pma_redirect.html
else
    echo "phpmyadmin already configured."
fi

# Compilation des assets (nécessaire après modification des fichiers .tsx)
cd /var/www/pterodactyl
yarn run build:production

# Remise en ligne du panneau
php /var/www/pterodactyl/artisan up

echo "phpMyAdmin successfully installed and panel rebuilt."