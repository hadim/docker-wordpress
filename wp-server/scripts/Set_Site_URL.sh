#!/usr/bin/env sh

if [ $# -lt 1 ]; then
    if [ -z "$SITE_URL" ]; then
        SITE_URL="http://localhost"
        echo "* Set default site url $SITE_URL"
    else
        echo "* Set site url for environment variable $SITE_URL"
    fi
else
    SITE_URL=$1
    echo "* Set site url from command line $SITE_URL"
fi

WORDPRESS_CONFIG="$WORDPRESS_INSTALL_DIR/wp-config.php"
WORDPRESS_TABLE_PREFIX=$(cat $WORDPRESS_CONFIG | grep "\$table_prefix" | cut -d \' -f 2)
echo "** Found table prefix : $WORDPRESS_TABLE_PREFIX"

MYSQL_RUN="mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD "

echo "** Check whether Wordpress is installed in the database"
if ! $MYSQL_RUN -sN $DB_DATABASE -e "desc ${WORDPRESS_TABLE_PREFIX}options" >> /dev/null 2>&1 ; then
    echo "** Wordpress does not seem to be installed."
    exit 1
fi

OLD_SITE=$($MYSQL_RUN -sN $DB_DATABASE -e "select option_value from ${WORDPRESS_TABLE_PREFIX}options WHERE option_name = 'siteurl';")

if [ "$OLD_SITE" = "$SITE_URL" ]; then
   echo "** New site url ($SITE_URL) already set in the current wordpress installation."
   exit 0
fi

echo "** Replace $OLD_SITE to $SITE_URL"
wp-cli search-replace --path=$WORDPRESS_INSTALL_DIR $OLD_SITE $SITE_URL --skip-columns=guid

echo "* New site url is now $SITE_URL (old was $OLD_SITE)"
