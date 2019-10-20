#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    # Get the name of the current directory.
    export SITE_DIR=${PWD##*/}
else
    export SITE_DIR=$1
fi

# Extract the extension of URL.
export ROOT_HOST=$(echo $SITE_DIR | cut -d. -f2)

# Create some directories if they does not exist
mkdir -p "../backups"
mkdir -p "../backups/$SITE_DIR"

# Define $WP_HOST_URL
if [ "$ROOT_HOST" == "local" ];
then
    echo ".local extension ar enot supported yet."

    # For now we disable local certificates.
    #mkdir -p "../certificates"
    #if [ ! -f "../certificates/${MAIN_VIRTUAL_HOST}.key" ]; then
    #    echo "Generate a self signed certificate for ${MAIN_VIRTUAL_HOST}."
    #    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    #                -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=${MAIN_VIRTUAL_HOST}" \
    #                -keyout "../certificates/${MAIN_VIRTUAL_HOST}".key \
    #                -out "../certificates/${MAIN_VIRTUAL_HOST}".crt
    #fi
    exit

else
    export WP_HOST_URL="${SITE_DIR}"
    export WP_SITE_URL="https://${WP_HOST_URL}"
fi

export WP_HOST_ID=$(echo ${WP_HOST_URL} | tr '.' '_' )

echo "Configuration correctly set for $WP_HOST_URL."
