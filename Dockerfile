FROM crazymax/rtorrent-rutorrent:latest

# COPY from irssi
RUN apk add --no-cache \
		ca-certificates \
		perl-libwww

ENV HOME /copy/data
RUN set -eux; \
	adduser -u 1001 -D -h "$HOME" user; \
	mkdir -p "$HOME/.irssi"; \
	chown -R user:user "$HOME"

ENV LANG C.UTF-8

ENV IRSSI_VERSION 1.2.3

RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		autoconf \
		automake \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		glib-dev \
		gnupg \
		libc-dev \
		libtool \
		lynx \
		make \
		ncurses-dev \
		openssl \
		openssl-dev \
		perl-dev \
		pkgconf \
		tar \
	; \
	\
	wget "https://github.com/irssi/irssi/releases/download/${IRSSI_VERSION}/irssi-${IRSSI_VERSION}.tar.xz" -O /tmp/irssi.tar.xz; \
	wget "https://github.com/irssi/irssi/releases/download/${IRSSI_VERSION}/irssi-${IRSSI_VERSION}.tar.xz.asc" -O /tmp/irssi.tar.xz.asc; \
	export GNUPGHOME="$(mktemp -d)"; \
# gpg: key DDBEF0E1: public key "The Irssi project <staff@irssi.org>" imported
	gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys 7EE65E3082A5FB06AC7C368D00CCB587DDBEF0E1; \
	gpg --batch --verify /tmp/irssi.tar.xz.asc /tmp/irssi.tar.xz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /tmp/irssi.tar.xz.asc; \
	\
	mkdir -p /usr/src/irssi; \
	tar -xf /tmp/irssi.tar.xz -C /usr/src/irssi --strip-components 1; \
	rm /tmp/irssi.tar.xz; \
	\
	cd /usr/src/irssi; \
	gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
	./configure \
		--build="$gnuArch" \
		--enable-true-color \
		--with-bot \
		--with-proxy \
		--with-socks \
	; \
	make -j "$(nproc)"; \
	make install; \
	\
	cd /; \
	rm -rf /usr/src/irssi; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-network --virtual .irssi-rundeps $runDeps; \
	apk del --no-network .build-deps; \
	\
# basic smoke test
	irssi --version

WORKDIR $HOME

# Install autodl
RUN apk add --no-cache --virtual .build-deps \
    autoconf \
    automake \
    coreutils \
    curl \
    dpkg-dev dpkg \
    gcc \
    glib-dev \
    gnupg \
    libc-dev \
    libssl1.1 \
    libxml2-dev \
    libtool \
    lynx \
    make \
    ncurses-dev \
    openssl \
    openssl-dev \
    perl-dev \
    pkgconf \
    screen \
    tar \
    unzip \
    wget \
    zlib && \
    curl -L http://cpanmin.us | perl - App::cpanminus && \
    cpanm --force Archive::Zip Net::SSLeay HTML::Entities XML::LibXML Digest::SHA JSON JSON::XS 

RUN mkdir -p /copy/data/.irssi/scripts/autorun && \
    cd /copy/data/.irssi/scripts && \
    curl -sL http://git.io/vlcND | grep -Po '(?<="browser_download_url": ")(.*-v[\d.]+.zip)' | xargs wget --quiet -O autodl-irssi.zip && \
    unzip -o autodl-irssi.zip && \
    rm autodl-irssi.zip && \
    cp autodl-irssi.pl autorun/ && \
    mkdir -p /copy/data/.autodl && \
    touch /copy/data/.autodl/autodl.cfg && \
    echo "[options]" > /copy/data/.autodl/autodl.cfg && \
    echo "rt-address = /var/run/rtorrent/scgi.socket" >> /copy/data/.autodl/autodl.cfg && \
    echo "gui-server-port = 51499" >> /copy/data/.autodl/autodl.cfg && \
    echo "gui-server-password = password" >> /copy/data/.autodl/autodl.cfg

RUN mkdir -p /copy/data/rutorrent/plugins/ && \
    apk add git && \
    cd /copy/data/rutorrent/plugins/ && \
    git clone https://github.com/autodl-community/autodl-rutorrent.git autodl-irssi && \
    cd autodl-irssi && \
    cp _conf.php conf.php && \
    sed -i 's|$autodlPort = 0;|$autodlPort = 51499;|g' conf.php && \
    sed -i 's|$autodlPassword = "";|$autodlPassword = "password";|g' conf.php

COPY rootfs /

# Pyrocore
RUN apk add --no-cache --virtual .build-deps \
		autoconf \
		automake \
		coreutils \
		dpkg-dev dpkg \
		gcc \
		glib-dev \
		gnupg \
		libc-dev \
		libtool \
		lynx \
		make \
		ncurses-dev \
		openssl \
		openssl-dev \
		perl-dev \
		pkgconf \
		python2 \
		python2-dev \
		screen \
		tar \
	&& \
	\
	python -m ensurepip && \
	rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools virtualenv

ENV PATH $PATH:/data/bin
RUN	mkdir -p $HOME/bin $HOME/.local && \
	git clone "https://github.com/pyroscope/pyrocore.git" $HOME/.local/pyroscope && \
	$HOME/.local/pyroscope/update-to-head.sh && \
	$HOME/bin/pyroadmin --version && \
	$HOME/bin/pyroadmin --create-config && \
	sed -i "s|rtorrent_rc = ~/.rtorrent.rc|rtorrent_rc = ~/rtorrent/.rtorrent.rc|g"  $HOME/.pyroscope/config.ini

WORKDIR /data
ENV HOME /data
RUN usermod -d /data rtorrent

VOLUME [ "/data", "/downloads", "/passwd" ]
ENTRYPOINT [ "/init" ]

HEALTHCHECK --interval=30s --timeout=20s --start-period=10s \
  CMD /usr/local/bin/healthcheck
