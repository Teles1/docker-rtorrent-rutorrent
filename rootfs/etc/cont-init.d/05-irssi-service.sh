#!/usr/bin/with-contenv sh

mkdir -p /etc/services.d/irssi
# cat > /etc/services.d/irssi/run <<EOL
# #!/usr/bin/with-contenv sh
# export HOME=/data
# export PWD=/data
# screen -D -m -S irssi s6-setuidgid rtorrent /usr/local/bin/irssi
# EOL
cat > /etc/services.d/irssi/run <<EOL
#!/usr/bin/execlineb -P
with-contenv
/bin/export HOME /data
/bin/export PWD /data
s6-setuidgid ${PUID}:${PGID}
/usr/bin/screen -D -m -S irssi /usr/local/bin/irssi
EOL
chmod +x /etc/services.d/irssi/run
