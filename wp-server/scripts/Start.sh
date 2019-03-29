#!/usr/bin/env bash

chown -R nginx:nginx /data

# Init wwww dir
if [ ! -d /data/htdocs ] ; then
  mkdir -p /data/htdocs
fi

# Init php-fpm
mkdir -p /data/logs/php-fpm

# Init nginx
mkdir -p /data/logs/nginx
mkdir -p /tmp/nginx

chown nginx:nginx /tmp/nginx
chown -R nginx:nginx /data

# Init wp-cli
if [ ! -d /data/bin ] ; then
  mkdir /data/bin
  chown nginx:nginx /data/bin
  cp /usr/bin/wp-cli /data/bin/wp-cli

  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /data/bin/wp-cli
fi

# Set permissions to backup dir
chown -R nginx:nginx $BACKUP_PARENT_DIR
chmod 777 -R $BACKUP_PARENT_DIR

# Add cron job to do backup every night at 4:30am
echo "* Set crontab job for backups"
(crontab -l 2>/dev/null; echo '30 4 * * * su nginx -c "bash /Backup.sh"') | crontab -

# Wait for database to be ready
while ! mysqladmin ping -h wp-db --silent; do
    echo "* Waiting for database server to be up."
    sleep 5s;
done

echo "* Database is now ready."

# Restore eventual backup
su nginx -c "bash /Restore.sh"

# Init wordpress directory if no backup restored
if [ $? -ne 0 ]; then
    if [ -z "$(ls -A $WORDPRESS_INSTALL_DIR)" ]; then

       echo "* Install Wordpress in $WORDPRESS_INSTALL_DIR"

       cd $WORDPRESS_INSTALL_DIR
       su nginx -c "wp-cli core download --locale=$WP_LOCALE --version=$WP_VERSION"

       su nginx -c "wp-cli core config --dbname=$DB_DATABASE --dbuser=$DB_USER \
                                       --dbpass=$DB_PASSWORD --dbhost=wp-db \
                                       --dbprefix=$WP_DB_PREFIX"

       su nginx -c "wp-cli core install --url=$MAIN_VIRTUAL_HOST \
                                        --title=$WP_TITLE \
                                        --admin_user=$WP_ADMIN_USER \
                                        --admin_password=$WP_ADMIN_PASSWORD \
                                        --admin_email=$WP_ADMIN_EMAIL"

    fi
fi

# Set site url
su nginx -c "bash /Set_Site_URL.sh"

# Remove wordpress cache
rm -fr /var/www/wordpress/wp-content/cache/

# If using SSL add some code to wp-config.php to handle this correctly
if [[ "$SITE_URL" =~ "https" ]]; then

  echo "** Add ssl config hack to wp-config.php"

  CONFIG_PATH="$WORDPRESS_INSTALL_DIR/wp-config.php"

  read -d '' NEW_SSL_CONFIG <<"EOF"
  <?php

  define('FORCE_SSL_ADMIN', true);
  if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)
    \$_SERVER['HTTPS']='on';
EOF

  tail -n +2 "$CONFIG_PATH" > "$CONFIG_PATH.tmp" && mv "$CONFIG_PATH.tmp" "$CONFIG_PATH"
  echo $NEW_SSL_CONFIG | cat - $CONFIG_PATH > temp && mv temp $CONFIG_PATH

fi

echo "* Launch php-fpm7"
php-fpm7

echo "* Launch crond"
crond

echo "* Launch nginx"
nginx