#!/usr/bin/with-contenv sh

cp -r /copy/data/. /data
chown -R rtorrent. /data/.autodl /data/.irssi /data/rutorrent
usermod -d /data rtorrent
export PATH=$PATH:/data/bin