FROM debian:jessie
MAINTAINER Egor Puzanov <epuzanov@gmx.de>

RUN apt-get update

RUN apt-get install -y python-pip python-lxml python-imaging python-bottle\
    python-dev python-pypdf python-apipkg python-py python-simplejson\
    python-roman python-gevent python-greenlet pdftk ploticus blahtexml\
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
    && apt-get clean

# Create cache temporary directories
RUN mkdir -p /data/mwcache

RUN echo "#!/bin/sh\n" > /usr/local/bin/start.sh \
    && echo "if [ -f /config/customconfig.py ]; then\n" >> /usr/local/bin/start.sh \
    && echo "    ln -s /config/customconfig.py /usr/local/lib/python2.7/dist-packages/customconfig.py\n" >> /usr/local/bin/start.sh \
    && echo "fi\n" >> /usr/local/bin/start.sh \
    && echo "nserve & mw-qserve & nslave --cachedir /data/mwcache & postman --cachedir /data/mwcache\n" >> /usr/local/bin/start.sh \
    && chmod 755 /usr/local/bin/start.sh

VOLUME /config
EXPOSE 8899

CMD ["/usr/local/bin/start.sh"]
