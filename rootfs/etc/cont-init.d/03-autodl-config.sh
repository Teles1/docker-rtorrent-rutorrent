#!/usr/bin/with-contenv sh

echo "Copying stuff for autodl-irssi and pyrocore without overwriting existing configs..."
chown -R rtorrent. /data
cp -prn /copy/data/. /data
usermod -d /data rtorrent
export PATH=$PATH:/data/bin