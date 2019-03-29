#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo "You need to specify the url of the website."
    echo "Usage: setup.sh example.com"
    return 0
fi

export SITE_DIR=$1
export ROOT_HOST=$(echo $SITE_DIR | cut -d. -f2)

# Create some directories if they does not exist
mkdir -p "../backups"
mkdir -p "../backups/$SITE_DIR"

export VIRTUAL_HOST="${SITE_DIR},www.${SITE_DIR}"

if [ "$ROOT_HOST" == "local" ];
then
    export MAIN_VIRTUAL_HOST="${SITE_DIR}"
    export LETSENCRYPT_HOST=""
    export LETSENCRYPT_EMAIL=""

    # For now we disable local certificates.
    #mkdir -p "../certificates"
    #if [ ! -f "../certificates/${MAIN_VIRTUAL_HOST}.key" ]; then
    #    echo "Generate a self signed certificate for ${MAIN_VIRTUAL_HOST}."
    #    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    #                -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${MAIN_VIRTUAL_HOST}" \
    #                -keyout "../certificates/${MAIN_VIRTUAL_HOST}".key \
    #                -out "../certificates/${MAIN_VIRTUAL_HOST}".crt
    #fi
    export SITE_URL="http://${MAIN_VIRTUAL_HOST}"

else
    export MAIN_VIRTUAL_HOST="www.${SITE_DIR}"
    export LETSENCRYPT_HOST="${VIRTUAL_HOST}"
    export LETSENCRYPT_EMAIL="marelo64@gmail.com"
    export SITE_URL="https://${MAIN_VIRTUAL_HOST}"
fi

echo "Configuration correctly set for $SITE_DIR."
