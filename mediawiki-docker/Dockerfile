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
    && sed -i "s/\$wgScriptPath ? \$wgScriptPath :/\"http:\/\/\" \. getHostByName\(getHostName\(\)\) \./g" ./Collection/RenderingAPI.php \
    && mkdir cache \
    && echo "Deny from all" > cache/.htaccess \
    && mkdir config \
    && ln -s /usr/src/mediawiki/extensions extensions \
    && ln -s /usr/src/mediawiki/includes includes \
    && ln -s /usr/src/mediawiki/languages languages \
    && ln -s /usr/src/mediawiki/maintenance maintenance \
    && ln -s /usr/src/mediawiki/mw-config mw-config \
    && ln -s /usr/src/mediawiki/resources resources \
    && ln -s /usr/src/mediawiki/skins skins \
    && ln -s /usr/src/mediawiki/vendor vendor \
    && ln -s /usr/src/mediawiki/api.php api.php \
    && ln -s /usr/src/mediawiki/autoload.php autoload.php \
    && ln -s /usr/src/mediawiki/img_auth.php img_auth.php \
    && ln -s /usr/src/mediawiki/index.php index.php \
    && ln -s /usr/src/mediawiki/load.php load.php \
    && ln -s /usr/src/mediawiki/opensearch_desc.php opensearch_desc.php \
    && ln -s /usr/src/mediawiki/profileinfo.php profileinfo.php \
    && ln -s /usr/src/mediawiki/thumb.php thumb.php \
    && ln -s /usr/src/mediawiki/thumb_handler.php thumb_handler.php \
    && ln -s /usr/src/mediawiki/wiki.phtml wiki.phtml

COPY mediawiki.conf /etc/apache2/
RUN echo "Include /etc/apache2/mediawiki.conf" >> /etc/apache2/apache2.conf

COPY docker-entrypoint.sh /entrypoint.sh

EXPOSE 80 443
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apachectl", "-e", "info", "-D", "FOREGROUND"]
