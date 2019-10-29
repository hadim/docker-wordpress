#!/usr/bin/with-contenv bash

BACKUP_DIR="wordpress_backup"

BACKUP_FILE=$(find $BACKUP_PARENT_DIR -maxdepth 1 -type f  -name "*wordpress_backup.7z" -exec basename {} \; | sort | tail -1 2> /dev/null)

if [ -z "$BACKUP_FILE" ]; then
    echo "* No backup file found in $BACKUP_PARENT_DIR"
    exit 0
fi

echo "* Init wordpress backup restoration for $BACKUP_FILE"

echo "** Uncompress backup files"
cd $BACKUP_PARENT_DIR
7zr x -y -o$BACKUP_DIR $BACKUP_FILE > /dev/null

echo "** Copy files to wordpress installation directory"
rm -fr $WORDPRESS_INSTALL_DIR
cp -r $BACKUP_DIR/wordpress $WORDPRESS_INSTALL_DIR
chown -R abc:abc $WORDPRESS_INSTALL_DIR

# Reset current MySQL database
echo "** Clear database"

MYSQL_RUN="mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD "
TABLES=$($MYSQL_RUN $DB_DATABASE -e 'show tables' | awk '{ print $1}' | grep -v '^Tables' )
for t in $TABLES
do
    echo "*** Deleting $t table from $DB_DATABASE database..."
    $MYSQL_RUN -u $DB_USER -p$DB_PASSWORD $DB_DATABASE -e "drop table $t"
done

# Restore MySQL database dump from backup
echo "** Restore database dump"
$MYSQL_RUN $DB_DATABASE < $BACKUP_DIR/db.sql

echo "** Cleanup"
cd $BACKUP_PARENT_DIR
rm -fr $BACKUP_DIR

# Get the DB Prefix of the restored backup or use default 'wp_'
cd $WORDPRESS_INSTALL_DIR
TMP_WP_DB_PREFIX=$(cat $WORDPRESS_INSTALL_DIR/wp-config.php | grep "\$table_prefix" | cut -d \' -f 2)
if [ ! -z "$TMP_WP_DB_PREFIX" ]; then
    WP_DB_PREFIX=$TMP_WP_DB_PREFIX
fi

# Set correct wordpress configuration
cd $WORDPRESS_INSTALL_DIR
rm -f wp-config.php
echo "** Setup Wordpress config with DB prefix : $WP_DB_PREFIX"
wp-cli core config --dbname=$DB_DATABASE \
                   --dbuser=$DB_USER \
                   --dbpass=$DB_PASSWORD \
                   --dbhost=$DB_HOST \
                   --dbprefix=$WP_DB_PREFIX

echo "* Restoration done for $BACKUP_FILE"
