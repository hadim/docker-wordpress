#!/usr/bin/env sh

BACKUP_PARENT_DIR="/backups"
BACKUP_DIR="wordpress_backup"
BACKUP_NAME=$(date +"%Y_%m_%d_%H_%M_wordpress_backup")

mkdir -p $BACKUP_PARENT_DIR
mkdir -p $BACKUP_PARENT_DIR/$BACKUP_DIR

echo "* Dump MySQLdatabase"
mysqldump -h wp-db -u $DB_USER -p$DB_PASSWORD $DB_DATABASE > $BACKUP_PARENT_DIR/$BACKUP_DIR/db.sql

echo "* Copy wordpress files"
cp -r $WORDPRESS_INSTALL_DIR/ $BACKUP_PARENT_DIR/$BACKUP_DIR/wordpress

echo "* Compress backup files and database"
cd $BACKUP_PARENT_DIR/$BACKUP_DIR
7zr a ../$BACKUP_NAME.7z * > /dev/null
chmod 755 ../$BACKUP_NAME.7z

echo "* Cleanup"
cd $BACKUP_PARENT_DIR
rm -fr $BACKUP_DIR

echo "* Backup saved as $BACKUP_NAME.7z"
