#!/bin/bash

set -e

if [ -d /config ]; then
	if [ -f /config/ssl.bundle.crt -a ! -h /usr/share/ca-certificates/ssl.bundle.crt ]; then
		cp /config/ssl.bundle.crt /usr/share/ca-certificates/ssl.bundle.crt
		dpkg-reconfigure ca-certificates
	fi
	if [ -f /config/customconfig.py -a ! -h /usr/local/lib/python2.7/dist-packages/customconfig.py ]; then
		ln -s /config/customconfig.py /usr/local/lib/python2.7/dist-packages/customconfig.py
	fi
fi

exec "$@"
