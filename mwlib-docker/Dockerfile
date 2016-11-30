FROM debian:jessie
MAINTAINER Egor Puzanov <epuzanov@gmx.de>

RUN apt-get update

RUN apt-get install -y python-pip python-lxml python-imaging python-bottle \
    python-dev python-pypdf python-apipkg python-py python-simplejson\
    python-roman python-gevent python-greenlet pdftk ploticus blahtexml\
    supervisor ca-certificates \
    && mkdir /etc/pip \
    && echo "[global]\ntrusted-host=pypi.pediapress.com\n" > /etc/pip/pip.conf \
    && pip install -i http://pypi.pediapress.com/simple/ mwlib \
    && pip install -i http://pypi.pediapress.com/simple/ mwlib.ext \
    && pip install -i http://pypi.pediapress.com/simple/ mwlib.rl \
    && rm /etc/pip/pip.conf \
    && rmdir /etc/pip \
    && apt-get remove -y python-dev python-pip python3 gcc g++ make \
    && apt-get autoremove -y \
    && apt-get install -y python-setuptools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/apt/archives/* \
    && mkdir -p /data/mwcache

COPY docker-entrypoint.sh /entrypoint.sh

VOLUME /config
EXPOSE 8899
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash", "-c", "nserve & mw-qserve & nslave --cachedir /data/mwcache & postman --cachedir /data/mwcache"]
