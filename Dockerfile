FROM phusion/baseimage:0.9.19

MAINTAINER Jasper van der Neut <jasper@neutstulen.nl>

ENV RT_VERSION 4.4.1
ENV RT_SHA1 a3c7aa5398af4f53c947b4bee8c91cecd5beb432

RUN echo mail > /etc/hostname; \
	apt-get update -yqq && \
	apt-get install -y --no-install-recommends \
		dbconfig-common \
		debconf \
		fonts-droid-fallback \
		fonts-noto-hinted \
		libapache-session-perl \
		libcgi-emulate-psgi-perl \
		libcgi-pm-perl \
		libcgi-psgi-perl \
		libclass-accessor-perl \
		libconvert-color-perl \
		libcrypt-eksblowfish-perl \
		libcrypt-ssleay-perl \
		libcrypt-x509-perl \
		libcss-minifier-xs-perl \
		libcss-squish-perl \
		libdata-guid-perl \
		libdata-ical-perl \
		libdata-pageset-perl \
		libdate-extract-perl \
		libdate-manip-perl \
		libdatetime-format-natural-perl \
		libdatetime-locale-perl \
		libdatetime-perl \
		libdbd-pg-perl \
		libdbi-perl \
		libdbix-searchbuilder-perl \
		libdevel-globaldestruction-perl \
		libemail-address-list-perl \
		libemail-address-perl \
		libfcgi-perl \
		libfcgi-procmanager-perl \
		libfile-sharedir-perl \
		libfile-which-perl \
		libgd-graph-perl \
		libgd-text-perl \
		libgnupg-interface-perl \
		libgraphviz-perl \
		libhtml-formattext-withlinks-andtables-perl \
		libhtml-formattext-withlinks-perl \
		libhtml-mason-perl \
		libhtml-mason-psgihandler-perl \
		libhtml-quoted-perl \
		libhtml-rewriteattributes-perl \
		libhtml-scrubber-perl \
		libhttp-message-perl \
		libipc-run3-perl \
		libipc-run-perl \
		libjavascript-minifier-xs-perl \
		libjson-perl \
		liblist-moreutils-perl \
		liblocale-maketext-fuzzy-perl \
		liblocale-maketext-lexicon-perl \
		liblog-dispatch-perl \
		libmailtools-perl \
		libmime-tools-perl \
		libmime-types-perl \
		libmodule-refresh-perl \
		libmodule-versions-report-perl \
		libnet-cidr-perl \
		libnet-ip-perl \
		libperlio-eol-perl \
		libplack-perl \
		libregexp-common-net-cidr-perl \
		libregexp-common-perl \
		libregexp-ipv6-perl \
		librole-basic-perl \
		libscope-upper-perl \
		libstring-shellquote-perl \
		libsymbol-global-name-perl \
		libterm-readkey-perl \
		libterm-readline-perl-perl \
		libtext-autoformat-perl \
		libtext-password-pronounceable-perl \
		libtext-quoted-perl \
		libtext-template-perl \
		libtext-wikiformat-perl \
		libtext-wrapper-perl \
		libtimedate-perl \
		libtime-parsedate-perl \
		libtree-simple-perl \
		libuniversal-require-perl \
		liburi-perl \
		libwww-perl \
		libxml-rss-perl \
		libxml-simple-perl \
		perl \
		postgresql-client \
		procps \
		spawn-fcgi \
		ucf \
	&& apt-get install -y --no-install-recommends \
		busybox-syslogd \
		ca-certificates \
		curl \
		dovecot-lmtpd \
		dovecot-sieve \
		git \
		gpgv2 \
		graphviz \
		make \
		msmtp \
		msmtp-mta \
		nginx-light \
		openssl \
		perl \
		postgresql-client \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update -yqq \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		cpanminus \
	&& cpanm \
		Business::Hours \
		Data::Page::Pageset \
		Mozilla::CA \
		Plack::Handler::Starlet \
	&& apt-get purge -y \
		build-essential \
		cpanminus \
	&& apt-get -y autoremove \
	&& apt-get purge -y $(dpkg -l | grep -- -dev | cut -d ' ' -f3) \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

# Build RT and extensions
#RUN /src/installext.sh https://github.com/bestpractical/rt-extension-mergeusers
#RUN /src/installext.sh https://github.com/bestpractical/rt-extension-resetpassword
#RUN /src/installext.sh https://github.com/bestpractical/rt-extension-commandbymail

COPY ./scripts/installext.sh /src/installext.sh

RUN apt-get update -yqq \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		libdatetime-event-ical-perl \
		libexpat1-dev \
		libpq-dev \
		libgd-dev \
		libssl-dev \
	&& cd /usr/local/src \
	&& curl -sSL "https://download.bestpractical.com/pub/rt/release/rt-${RT_VERSION}.tar.gz" -o rt.tar.gz \
	&& echo "${RT_SHA1}  rt.tar.gz" | shasum -c \
	&& tar -xvzf rt.tar.gz \
	&& rm rt.tar.gz \
	&& cd "rt-${RT_VERSION}" \
	&& ./configure \
	--disable-gpg \
	--disable-smime \
	--enable-gd \
	--enable-graphviz \
	--with-db-type=Pg \
	--with-web-handler=fastcgi \
	&& make testdeps \
	&& make install \
	&& /src/installext.sh https://github.com/bestpractical/rt-extension-activityreports \
	&& /src/installext.sh https://github.com/bestpractical/rt-extension-repeatticket \
	&& apt-get purge -y \
		build-essential \
		libexpat1-dev \
		libpq-dev \
		libgd-dev \
		libssl-dev \
	&& apt-get -y autoremove \
	&& apt-get purge -y $(dpkg -l | grep -- -dev | cut -d ' ' -f3) \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

RUN cp /src/rt-extension-repeatticket/bin/rt-repeat-ticket /opt/rt4/sbin

RUN mkdir -p /opt/rt4/local/html/Callbacks/MyCallbacks/Elements/MakeClicky
COPY ./misc/MakeClicky /opt/rt4/local/html/Callbacks/MyCallbacks/Elements/MakeClicky/Default

COPY ./scripts/rtcron /usr/bin/rtcron
COPY ./scripts/rtinit /usr/bin/rtinit

COPY ./etc/nginx.conf /etc/nginx/nginx.conf

# Configure RT
COPY ./RT_SiteConfig.pm /opt/rt4/etc/RT_SiteConfig.pm
RUN mv /opt/rt4/var /data
RUN ln -s /data /opt/rt4/var
RUN mkdir /var/log/rt4

# Add system services
COPY ./svc /etc/service
CMD ["/sbin/my_init"]

COPY ./etc/dovecot /etc/dovecot
RUN mkdir -p /var/run/dovecot/sieve-pipe \
	&& mkdir /usr/lib/dovecot/sieve-pipe \
	&& ln -s /opt/rt4/bin/rt-mailgate /usr/lib/dovecot/sieve-pipe/rt-mailgate \
	&& cd /etc/dovecot \
	&& sievec default.sieve \
	&& rm -rf /tmp/* /var/tmp/* /usr/local/src/*

VOLUME ["/data"]
EXPOSE 8024
EXPOSE 80


