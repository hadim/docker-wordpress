#!/usr/bin/env sh

BACKUP_PARENT_DIR="/backups"
BACKUP_DIR="wordpress_backup"
BACKUP_NAME=$(date +"%Y_%m_%d_%H_%M_wordpress_backup")

rm -fr $BACKUP_PARENT_DIR/$BACKUP_DIR

mkdir -p $BACKUP_PARENT_DIR
mkdir -p $BACKUP_PARENT_DIR/$BACKUP_DIR

echo "* Dump MySQLdatabase"
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_DATABASE > $BACKUP_PARENT_DIR/$BACKUP_DIR/db.sql

if [[ $? -eq 0 ]]; then
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
	exit 0
else
  echo "Wordpress backup failed during mysql dump."
  touch "${BACKUP_NAME}.FAILED"
  exit 1
fi


