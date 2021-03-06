#!/usr/bin/with-contenv sh

mkdir -p /etc/services.d/nginx
cat > /etc/services.d/nginx/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
nginx -g "daemon off;"
EOL
chmod +x /etc/services.d/nginx/run

mkdir -p /etc/services.d/php-fpm
cat > /etc/services.d/php-fpm/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
s6-setuidgid ${PUID}:${PGID}
php-fpm7 -F
EOL
chmod +x /etc/services.d/php-fpm/run

mkdir -p /etc/services.d/rtorrent
cat > /etc/services.d/rtorrent/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/bin/export PWD /data/rtorrent
s6-setuidgid ${PUID}:${PGID}
rtorrent -D -o import=/etc/rtorrent/.rtlocal.rc -i ${WAN_IP}
EOL
chmod +x /etc/services.d/rtorrent/run

mkdir -p /etc/services.d/irssi
cat > /etc/services.d/irssi/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/bin/export HOME /data
/bin/export PWD /data
s6-setuidgid ${PUID}:${PGID}
/usr/bin/screen -D -m -S irssi /usr/local/bin/irssi
EOL
chmod +x /etc/services.d/irssi/run