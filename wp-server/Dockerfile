FROM alpine:3.9
MAINTAINER Hadrien Mary <hadrien.mary@gmail.com>

RUN apk update \
    && apk add --no-cache bash less nano nginx ca-certificates \
    php7-fpm php7-json php7-zlib php7-xml php7-pdo php7-phar php7-openssl \
    php7-pdo_mysql php7-mysqli php7-session \
    php7-gd php7-iconv php7-mcrypt \
    php7-curl php7-opcache php7-ctype php7-apcu \
    php7-intl php7-bcmath php7-mbstring php7-dom php7-xmlreader \
    mysql-client openssh-client git curl rsync sudo p7zip \
    libjpeg-turbo-utils \
    && apk add -u --no-cache musl && apk --update --no-cache add tar
RUN rm -rf /var/cache/apk/*

ENV TERM="xterm"
ENV PATH /data/bin:$PATH
ENV WORDPRESS_INSTALL_DIR /data/htdocs
ENV BACKUP_PARENT_DIR /backups

RUN sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php7/php.ini && \
    sed -i "s/nginx:x:100:101:nginx:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:nginx:\/data:\/bin\/bash/g" /etc/passwd && \
    sed -i "s/nginx:x:100:101:nginx:\/var\/lib\/nginx:\/sbin\/nologin/nginx:x:100:101:nginx:\/data:\/bin\/bash/g" /etc/passwd-

ADD conf/nginx.conf /etc/nginx/
ADD conf/php-fpm.conf /etc/php7/

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && chmod +x wp-cli.phar && mv wp-cli.phar /usr/bin/wp-cli && chown nginx:nginx /usr/bin/wp-cli

# Copy scripts
COPY scripts/Set_Site_URL.sh /Set_Site_URL.sh
COPY scripts/Start.sh /Start.sh
COPY scripts/Backup.sh /Backup.sh
COPY scripts/Restore.sh /Restore.sh

VOLUME ["/data"]
VOLUME ["/backups"]

ENTRYPOINT ["bash", "/Start.sh"]
