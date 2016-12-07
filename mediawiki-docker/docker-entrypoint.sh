#!/bin/bash

set -e

: ${MEDIAWIKI_SITE_NAME:=MediaWiki}
: ${MEDIAWIKI_SITE_LANG:=en}
: ${MEDIAWIKI_ADMIN_USER:=admin}
: ${MEDIAWIKI_ADMIN_PASS:=password}
: ${MEDIAWIKI_DB_TYPE:=mysql}
: ${MEDIAWIKI_DB_HOST:=db}
: ${MEDIAWIKI_DB_PORT:=3306}
: ${MEDIAWIKI_DB_SCHEMA:=mediawiki}
: ${MEDIAWIKI_DB_USER:=root}
: ${MEDIAWIKI_DB_PASSWORD:=password}
: ${MEDIAWIKI_DB_NAME:=wikidb}
: ${MEDIAWIKI_UPDATE:=false}
: ${MEDIAWIKI_MAX_UPLOAD_SIZE:=209715200}

if [ $MEDIAWIKI_DB_TYPE = 'mysql' ]; then
    # Wait for the DB to come up
    while [ `/bin/nc $MEDIAWIKI_DB_HOST $MEDIAWIKI_DB_PORT < /dev/null > /dev/null; echo $?` != 0 ]; do
        echo "Waiting for database to come up at $MEDIAWIKI_DB_HOST:$MEDIAWIKI_DB_PORT..."
        sleep 1
    done

TERM=dumb php -- $MEDIAWIKI_DB_TYPE $MEDIAWIKI_DB_HOST $MEDIAWIKI_DB_PORT $MEDIAWIKI_DB_SCHEMA $MEDIAWIKI_DB_USER $MEDIAWIKI_DB_PASSWORD $MEDIAWIKI_DB_NAME <<'EOPHP'
<?php
$MEDIAWIKI_DB_TYPE = $argv[1];
$MEDIAWIKI_DB_HOST = $argv[2];
$MEDIAWIKI_DB_PORT = $argv[3];
$MEDIAWIKI_DB_SCHEMA = $argv[4];
$MEDIAWIKI_DB_USER = $argv[5];
$MEDIAWIKI_DB_PASSWORD = $argv[6];
$MEDIAWIKI_DB_NAME = $argv[7];

if ($MEDIAWIKI_DB_TYPE == 'mysql') {
	$db = new mysqli($MEDIAWIKI_DB_HOST, $MEDIAWIKI_DB_USER, $MEDIAWIKI_DB_PASSWORD, '', (int) $MEDIAWIKI_DB_PORT);
}

if ($db->connect_error) {
	file_put_contents('php://stderr', 'MySQL Connection Error: (' . $db->connect_errno . ') ' . $db->connect_error . "\n");
	exit(1);
}

if (!$db->query('CREATE DATABASE IF NOT EXISTS `' . $db->real_escape_string($MEDIAWIKI_DB_NAME) . '`')) {
	file_put_contents('php://stderr', 'MySQL "CREATE DATABASE" Error: ' . $db->error . "\n");
	$db->close();
	exit(1);
}

$db->close();
?>
EOPHP
fi

cd /var/www/html

: ${MEDIAWIKI_SHARED:=/data}
if [ -d "$MEDIAWIKI_SHARED" ]; then
	# If there is no LocalSettings.php but we have one under the shared
	# directory, symlink it
	if [ -e "$MEDIAWIKI_SHARED/LocalSettings.php" -a ! -e LocalSettings.php ]; then
		ln -s "$MEDIAWIKI_SHARED/LocalSettings.php" LocalSettings.php
	fi

	if [ -f "$MEDIAWIKI_SHARED/php.ini" ]; then
		echo >&2 "Found 'php.ini' file in data volume, creating symbolic link."
		cp $MEDIAWIKI_SHARED/php.ini /etc/php5/apache2/conf.d/30-mediawiki.ini
	elif [ ! -f /etc/php5/apache2/conf.d/30-mediawiki.ini ] ; then
		echo "upload_max_filesize = $MEDIAWIKI_MAX_UPLOAD_SIZE" > /etc/php5/apache2/conf.d/30-mediawiki.ini
		echo "post_max_size = $MEDIAWIKI_MAX_UPLOAD_SIZE" >> /etc/php5/apache2/conf.d/30-mediawiki.ini
	fi

	# Creating the shared directory $MEDIAWIKI_SHARED/images 
	if [ ! -d "$MEDIAWIKI_SHARED/images" ]; then
		mkdir "$MEDIAWIKI_SHARED/images"
	fi
	if [ ! -h /var/www/html/images ]; then
		ln -s "$MEDIAWIKI_SHARED/images" images
	fi

	# If an extensions folder exists inside the shared directory, as long as
	# /var/www/html/extensions is not already a symbolic link, then replace it
	if [ -d "$MEDIAWIKI_SHARED/extensions" -a ! -h /var/www/html/extensions ]; then
		echo >&2 "Found 'extensions' folder in data volume, creating symbolic link."
		rm -rf /var/www/html/extensions
		ln -s "$MEDIAWIKI_SHARED/extensions" /var/www/html/extensions
	fi

	# If a skins folder exists inside the shared directory, as long as
	# /var/www/html/skins is not already a symbolic link, then replace it
	if [ -d "$MEDIAWIKI_SHARED/skins" -a ! -h /var/www/html/skins ]; then
		echo >&2 "Found 'skins' folder in data volume, creating symbolic link."
		rm -rf /var/www/html/skins
		ln -s "$MEDIAWIKI_SHARED/skins" /var/www/html/skins
	fi

	# If a vendor folder exists inside the shared directory, as long as
	# /var/www/html/vendor is not already a symbolic link, then replace it
	if [ -d "$MEDIAWIKI_SHARED/vendor" -a ! -h /var/www/html/vendor ]; then
		echo >&2 "Found 'vendor' folder in data volume, creating symbolic link."
		rm -rf /var/www/html/vendor
		ln -s "$MEDIAWIKI_SHARED/vendor" /var/www/html/vendor
	fi

	# Attempt to enable SSL support if explicitly requested
	if [ $MEDIAWIKI_ENABLE_SSL = true ]; then
		echo >&2 'info: enabling ssl'
		a2enmod ssl
		if [ ! -f "$MEDIAWIKI_SHARED/ssl.key" -o ! -f "$MEDIAWIKI_SHARED/ssl.crt" -o ! -f "$MEDIAWIKI_SHARED/ssl.bundle.crt" ]; then
			HOSTNAME=`echo $MEDIAWIKI_SITE_SERVER | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/"`
			openssl req -x509 -newkey rsa:4096 -keyout $MEDIAWIKI_SHARED/ssl.key -out $MEDIAWIKI_SHARED/ssl.crt -days 365 -nodes -subj "/C=DE/ST=Bonn/L=NRW/O=$MEDIAWIKI_SITE_NAME/OU=Org/CN=$HOSTNAME"
			cp $MEDIAWIKI_SHARED/ssl.crt $MEDIAWIKI_SHARED/ssl.bundle.crt
		fi
		cp "$MEDIAWIKI_SHARED/ssl.key" /etc/apache2/ssl.key
		cp "$MEDIAWIKI_SHARED/ssl.crt" /etc/apache2/ssl.crt
		cp "$MEDIAWIKI_SHARED/ssl.bundle.crt" /etc/apache2/ssl.bundle.crt
	elif [ -e "/etc/apache2/mods-enabled/ssl.load" ]; then
		echo >&2 'warning: disabling ssl'
		a2dismod ssl
	fi
else
	echo >&2 'Did you forget to mount the volume with -v?'
	exit 1
fi

# Fix file ownership and permissions
chown -R www-data: .
chown -R www-data:www-data $MEDIAWIKI_SHARED/images
chmod 755 $MEDIAWIKI_SHARED/images

# If there is no LocalSettings.php, create one using maintenance/install.php
if [ ! -e "$MEDIAWIKI_SHARED/LocalSettings.php" -a ! -z "$MEDIAWIKI_SITE_SERVER" ]; then
	php maintenance/install.php \
		--confpath /var/www/html \
		--dbname "$MEDIAWIKI_DB_NAME" \
		--dbschema "$MEDIAWIKI_DB_SCHEMA" \
		--dbport "$MEDIAWIKI_DB_PORT" \
		--dbserver "$MEDIAWIKI_DB_HOST" \
		--dbtype "$MEDIAWIKI_DB_TYPE" \
		--dbuser "$MEDIAWIKI_DB_USER" \
		--dbpass "$MEDIAWIKI_DB_PASSWORD" \
		--installdbuser "$MEDIAWIKI_DB_USER" \
		--installdbpass "$MEDIAWIKI_DB_PASSWORD" \
		--server "$MEDIAWIKI_SITE_SERVER" \
		--scriptpath "" \
		--lang "$MEDIAWIKI_SITE_LANG" \
		--pass "$MEDIAWIKI_ADMIN_PASS" \
		"$MEDIAWIKI_SITE_NAME" \
		"$MEDIAWIKI_ADMIN_USER"

        for EXT in $MEDIAWIKI_EXTENSIONS
            do
                echo "require_once \"\$IP/extensions/$EXT/$EXT.php\";" >> LocalSettings.php
            done
        # If we have a mounted share volume, move the LocalSettings.php to it
        # so it can be restored if this container needs to be reinitiated
        if [ -d "$MEDIAWIKI_SHARED" ]; then
            # Move generated LocalSettings.php to share volume
            mv LocalSettings.php "$MEDIAWIKI_SHARED/LocalSettings.php"
            ln -s "$MEDIAWIKI_SHARED/LocalSettings.php" LocalSettings.php
        fi
        if [[ $MEDIAWIKI_EXTENSIONS == *"Collection"* ]] ; then
            php maintenance/createAndPromote.php --bot --conf $MEDIAWIKI_SHARED/LocalSettings.php mwlib $MEDIAWIKI_ADMIN_PASS
            sed -i 's/wgEnableUploads = false/wgEnableUploads = true/g' $MEDIAWIKI_SHARED/LocalSettings.php
            sed -i "s/wgLanguageCode = \"en\"/wgLanguageCode = \"$MEDIAWIKI_SITE_LANG\"/g" $MEDIAWIKI_SHARED/LocalSettings.php
            sed -i "s/#\$wgCacheDirectory/\$wgCacheDirectory/g" $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgEnableWriteAPI = true;" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgMaxArticleSize = 10240;" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgMaxUploadSize = $MEDIAWIKI_MAX_UPLOAD_SIZE;" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgFileExtensions = array_merge(\$wgFileExtensions, array('pdf', 'docx', 'xlsx', 'txt'));" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgGroupPermissions['*']['read'] = false;" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgGroupPermissions['user']['collectionsaveasuserpage'] = true;" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgGroupPermissions['autoconfirmed']['collectionsaveascommunitypage'] = true;" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgCollectionPODPartners = false;" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgCollectionFormats = array('rl' => 'PDF', 'odf' => 'ODT');" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgCollectionMWServeCredentials=\"mwlib:$MEDIAWIKI_ADMIN_PASS\";" >> $MEDIAWIKI_SHARED/LocalSettings.php
            echo "\$wgCollectionMWServeURL=\"http://mwlib:8899\";" >> $MEDIAWIKI_SHARED/LocalSettings.php
        fi
fi

# If LocalSettings.php exists, then attempt to run the update.php maintenance
# script. If already up to date, it won't do anything, otherwise it will
# migrate the database if necessary on container startup. It also will
# verify the database connection is working.
if [ -e "LocalSettings.php" -a $MEDIAWIKI_UPDATE = true ]; then
	echo >&2 'info: Running maintenance/update.php';
	php maintenance/update.php --quick --conf ./LocalSettings.php
fi


exec "$@"
