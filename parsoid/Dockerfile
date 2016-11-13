FROM debian:jessie
MAINTAINER Egor Puzanov <epuzanov@gmx.de>

RUN apt-get update

RUN set -x; \
    echo "deb https://releases.wikimedia.org/debian jessie-mediawiki main" > /etc/apt/sources.list.d/parsoid.list \
    && gpg --keyserver keys.gnupg.net --recv-keys 664C383A3566A3481B942F007A322AC6E84AFDD2
    && apt-get install -y --no-install-recommends apt-transport-https \
    && apt-get install -y --force-yes --no-install-recommends parsoid \
    && apt-get clean \
    && update-rc.d parsoid disable \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data

VOLUME /data
EXPOSE 8000

RUN echo "#!/bin/sh\n" > /entrypoint.sh \
    && echo "if [ -f /data/settings.js ]; then\n" >> /entrypoint.sh \
    && echo "    rm /etc/mediawiki/parsoid/settings.js\n" >> /entrypoint.sh \
    && echo "    ln -s /data/settings.js /etc/mediawiki/parsoid/settings.js\n" >> /entrypoint.sh \
    && echo "else\n" >> /entrypoint.sh \
    && echo "    hostip=\$(ip route|awk '/default/ { print \$3 }')\n" >> /entrypoint.sh \
    && echo "    sed -i 's/http:\/\/localhost/http:\/\/\$hostip/' /etc/mediawiki/parsoid/settings.js\n" >> /entrypoint.sh \
    && echo "fi\n" >> /entrypoint.sh \
    && echo "exec \"\$@\"\n" >> /entrypoint.sh \
    && chmod 755 /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/nodejs", "/usr/lib/parsoid/src/bin/server.js" ,"-c" ,"/etc/mediawiki/parsoid/settings.js"]
