FROM alpine:3.10
MAINTAINER Hadrien Mary <hadrien.mary@gmail.com>

ENV S6_VERSION "v1.22.1.0"
ENV S6_ARCH "amd64"

RUN apk update \
    && apk add --no-cache tzdata bash less nano nginx ca-certificates \
    php7-fpm php7-json php7-zlib php7-xml php7-pdo php7-phar php7-openssl \
    php7-pdo_mysql php7-mysqli php7-session \
    php7-gd php7-iconv php7-mcrypt \
    php7-curl php7-opcache php7-ctype php7-apcu \
    php7-intl php7-bcmath php7-mbstring php7-dom php7-xmlreader \
    mysql-client openssh-client git curl rsync sudo p7zip \
    libjpeg-turbo-utils \
    && apk add -u --no-cache musl && apk --update --no-cache add tar
RUN rm -rf /var/cache/apk/*

RUN curl -L -s https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-${S6_ARCH}.tar.gz | tar xvzf - -C /

ENV TERM="xterm"

# If you modify $WORDPRESS_INSTALL_DIR
# you also need to modify paths in conf/nginx.conf
# and conf/php-fpm.conf.
ENV WORDPRESS_INSTALL_DIR /var/www/wordpress
ENV BACKUP_PARENT_DIR /backups

RUN mkdir /backups \
    && addgroup -S abc && adduser -S abc -G abc -s /bin/bash abc 

RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php7/php.ini && \
    sed -i "s/abc:x:100:101:abc:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:abc:\/data:\/bin\/bash/g" /etc/passwd && \
    sed -i "s/abc:x:100:101:abc:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:abc:\/data:\/bin\/bash/g" /etc/passwd-

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp-cli && chown abc:abc /usr/bin/wp-cli

# Copy files to image
COPY rootfs /

VOLUME /backups

ENTRYPOINT [ "/init" ]
