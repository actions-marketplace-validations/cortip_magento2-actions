#!/usr/bin/env bash

set -e

# operation to make before the switch of the release folder

php /usr/local/bin/composer install

echo "✂️ remove cached stuff"
rm -rf pub/static/*
rm -rf var/view_preprocessed/*
rm -rf var/cache/*
rm -rf var/generation/*
rm -rf var/page_cache/*

echo "📀 upgrade magento to new modules and stuff"
php bin/magento setup:upgrade

echo "👮🏻 fix access rights"
chmod 777 -R var pub generated

echo "🏗 Set setting to combine assets"
#https://devdocs.magento.com/guides/v2.4/frontend-dev-guide/themes/js-bundling.html
#https://devdocs.magento.com/guides/v2.4/config-guide/prod/config-reference-most.html
php bin/magento config:set dev/js/enable_js_bundling 0
php bin/magento config:set dev/js/minify_files 0
php bin/magento config:set dev/static/sign 0
php bin/magento config:set dev/js/merge_files 0

php bin/magento config:set dev/css/merge_css_files 0
php bin/magento config:set dev/css/minify_files 0

echo "👨🏼‍🚀 set shop to production mode"
php bin/magento deploy:mode:set default

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
