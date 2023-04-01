#!/usr/bin/bash

FILE=composer.lock
ENV_FILE=app/etc/env.php

# changing memory_limit in php.ini
cp -rf /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
sed -i 's.memory_limit =.;memory_limit =.' /usr/local/etc/php/php.ini \
  && echo "memory_limit = 512M" >> /usr/local/etc/php/php.ini


# adding mageplaza record in hosts file
echo "dashboard.mageplaza.com:198.199.79.159" >> /etc/hosts

function installProject() {

   php bin/magento setup:install \
       --base-url="${MAGENTO_URL}" \
       --backend-frontname="${BACKEND_FRONTNAME}" \
       --db-host="${DB_HOST}" \
       --db-name=${DB_NAME} \
       --db-user=${DB_USER} \
       --db-password=${DB_USER_PASSWORD} \
       --admin-firstname="${ADMIN_FIRSTNAME}" \
       --admin-lastname="${ADMIN_LASTNAME}" \
       --admin-email="${ADMIN_EMAIL}" \
       --admin-user="${ADMIN_USER}" \
       --admin-password="${ADMIN_PASSWORD}" \
       --language="${LANGUAGE}" \
       --currency="${CURRENCY}" \
       --timezone="${TIMEZONE}" \
       --use-rewrites="${URL_REWRITES}" \
       --search-engine="${SEARCH_ENGINE}" \
       --elasticsearch-host="${SEARCH_ENGINE_HOST}" \
       --elasticsearch-port="${SEARCH_ENGINE_PORT}" \
       --cleanup-database
}

function runM2Commands() {
  php bin/magento setup:upgrade
  php bin/magento setup:di:compile
  php bin/magento setup:static-content:deploy -f
  php bin/magento cache:flush
}

function setRabbitMQ() {
    if [[ $SETUP_INSTALL_RABBITMQ == 1 ]]; then
      php bin/magento setup:config:set --amqp-host="${RABBITMQ_VHOST}" \
            --amqp-port="${RABBITMQ_PORT}" \
            --amqp-user="${RABBITMQ_USER}" \
            --amqp-password="${RABBITMQ_PASS}" \
            --amqp-virtualhost="${RABBITMQ_VIRTUAL_HOST}"
      php bin/magento cache:flush
    fi
}

function createProject() {
  if [[ -z $MAGENTO_VERSION ]]; then
    composer create-project --repository-url="${REPO}" magento/project-community-edition "${INSTALLATION_DIR}"
  else
    composer create-project --repository-url="${REPO}" magento/project-community-edition="${MAGENTO_VERSION}" "${INSTALLATION_DIR}"
  fi
}

function installMagePlazaSmtp() {
    if [[ $INSTALL_MAGEPLAZA_SMTP == 1 ]]; then
       composer require "${MODULE_NAME}"
     fi
}

function setDeployMode() {
  if [[ -z $DEPLOY_MODE ]]; then
    php bin/magento deploy:mode:set "${DEPLOY_MODE}"
  fi
}

function installSampleData() {
  if [[ $INSTALL_SAMPLE_DATA == 1 ]]; then
    php bin/magento sampledata:deploy
  fi
}

if [[ ! -f "$FILE" ]]; then
   createProject
   installProject
   setRabbitMQ
   installMagePlazaSmtp
   setDeployMode
   installSampleData
   runM2Commands
elif [[ ! -f "$ENV_FILE" ]]; then
   installProject
fi

echo "**********STARTING CONTAINER**********";
exec docker-php-entrypoint php-fpm