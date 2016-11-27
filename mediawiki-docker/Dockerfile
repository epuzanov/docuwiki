FROM debian:jessie
MAINTAINER Egor Puzanov <epuzanov@gmx.de>

ARG MEDIAWIKI_VERSION=wmf/1.29.0-wmf.1
ENV MEDIAWIKI_VERSION $MEDIAWIKI_VERSION

ARG MEDIAWIKI_EXTENSIONS="CategoryTree ImageMap Collection"
ENV MEDIAWIKI_EXTENSIONS $MEDIAWIKI_EXTENSIONS

RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        apache2 \
        libapache2-mod-php5 \
        php5-mysql \
        php5-pgsql \
        php5-sqlite \
        php5-cli \
        php5-gd \
        php5-curl \
        imagemagick \
        netcat \
        git \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/* \
    && a2enmod rewrite \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && rm /var/www/html/index.html

RUN set -x; \
    mkdir -p /usr/src \
    && git clone \
        --depth 1 \
        -b $MEDIAWIKI_VERSION \
        https://gerrit.wikimedia.org/r/p/mediawiki/core.git \
        /usr/src/mediawiki \
    && cd /usr/src/mediawiki \
    && git submodule update --init skins \
    && git submodule update --init vendor \
    && cd extensions \
    && for EXT in $MEDIAWIKI_EXTENSIONS ; do git submodule update --init $EXT \
    && cd $EXT \
    && git checkout $MEDIAWIKI_VERSION \
    && git submodule update --init \
    && cd .. ; done \
    && cd /var/www/html \
    && ln -s /usr/src/mediawiki/* . \
    && rm images

COPY mediawiki.conf /etc/apache2/
RUN echo "Include /etc/apache2/mediawiki.conf" >> /etc/apache2/apache2.conf

COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 80 443
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apachectl", "-e", "info", "-D", "FOREGROUND"]
