#!/usr/bin/env bash

# check and edit this path (public path of magento)

if [ ! -f app/etc/env.php ]
then
  echo "This is the first deploy? You must set magento env.php"
  exit 3
fi
#
#chmod -R 775 .
#chown -R www:www-data .
#
#composer install

echo "Import magento config"
php bin/magento app:config:import --no-interaction

echo "Check setup:upgrade status"
# use --no-ansi to avoid color characters
message=$(php bin/magento setup:db:status --no-ansi)

if [[ ${message:0:3} == "All" ]]; then
  echo "No setup upgrade - clear cache";
  php bin/magento cache:clean
else
  echo "Run setup:upgrade - maintenance mode"
  php bin/magento maintenance:enable
  php bin/magento setup:upgrade --keep-generated
  php bin/magento maintenance:disable
  php bin/magento cache:flush
fi

echo "📀 upgrade magento to new modules and stuff"
php bin/magento setup:upgrade

echo "✂️ remove cached stuff"
rm -rf pub/static/*
rm -rf var/view_preprocessed/*
rm -rf var/cache/*
rm -rf var/generation/*
rm -rf var/page_cache/*

echo "👮🏻 fix access rights"
chmod 777 -R var pub generated
echo "👨🏼‍🚀 set shop to production mode"
php bin/magento deploy:mode:set production

#https://devdocs.magento.com/guides/v2.4/frontend-dev-guide/themes/js-bundling.html
#https://devdocs.magento.com/guides/v2.4/config-guide/prod/config-reference-most.html
php bin/magento config:set dev/js/enable_js_bundling 1
php bin/magento config:set dev/js/minify_files 1
php bin/magento config:set dev/static/sign 0
php bin/magento config:set dev/js/merge_files 0

php bin/magento config:set dev/css/merge_css_files 1
php bin/magento config:set dev/css/minify_files 1

echo "⚙️ compile things"
php bin/magento setup:di:compile
echo "🪂 deploy compiled stuff"
php bin/magento setup:static-content:deploy -f
echo "👮🏻 fix access rights"
chmod 777 -R var pub generated
echo "🧹 running Magento clean cache commands"
php bin/magento cache:clean
php bin/magento cache:flush
echo "♻️ flushed cache"

#make stuff writable
echo "👮🏻 fix access rights"
chmod -R 777 .
chown -R www:www-data .