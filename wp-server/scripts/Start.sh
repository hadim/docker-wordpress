#!/usr/bin/env bash

chmod +x /Backup.sh

# Init wwww dir
if [ ! -d $WORDPRESS_INSTALL_DIR ] ; then
  mkdir -p $WORDPRESS_INSTALL_DIR
fi

# Init nginx
mkdir -p /tmp/nginx
chown nginx:nginx /tmp/nginx
chown -R nginx:nginx $(dirname $WORDPRESS_INSTALL_DIR)
mkdir -p /var/log/nginx

# Set permissions to backup dir
chown -R nginx:nginx $BACKUP_PARENT_DIR
chmod 777 -R $BACKUP_PARENT_DIR

# Add cron job to do backup every night at 4:30am
echo "* Set crontab job for backups"
crontab -r
(crontab -l 2>/dev/null; echo '30 4 * * * "./Backup.sh >> /var/log/backup.log 2>&1"') | crontab -

# Wait for database to be ready
while ! mysqladmin ping -h $DB_HOST --silent; do
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
                                    --dbpass=$DB_PASSWORD --dbhost=$DB_HOST \
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
rm -fr $WORDPRESS_INSTALL_DIR/wp-content/cache/

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

# Forward request and error logs to docker log collector.
echo "* Redirect nginx logs"
chown -R nginx:nginx /var/log
su nginx -c "ln -sf /dev/stdout /var/log/nginx_access.log"
su nginx -c "ln -sf /dev/stderr /var/log/nginx_error.log"
su nginx -c "ln -sf /dev/stderr /var/log/php-fpm.log"
su nginx -c "ln -sf /dev/stdout /var/log/backup.log"

echo "* Launch php-fpm7"
php-fpm7

echo "* Launch crond"
crond

echo "* Launch nginx"
nginx