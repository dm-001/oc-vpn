FROM alpine:3.16.2

LABEL maintainer="dm" \
      version=0.2 \
      description="Openconnect VPN server with saml 2.0 auth"

# Forked from MorganOnBass https://github.com/MorganOnBass/docker-ocserv-saml
# and using https://gitlab.com/morganofbass/ocserv.git for SAML 2.0 auth.
# Rebased to Alpine 3.16.
# Key dependencies updated: xmlsec1, lasso to current verion.
# Default ocserv security posture increased. Forward secrecy enforced, compatability
# with older clients discarded to remove old DTLS issues.
# Cert request and renewal automated.

# build ocserv
RUN buildDeps=" \
            autoconf \
            automake \
            curl-dev \
            libtool \
            libxml2-dev \
            py-six \
            python3 \
            perl-dev \
            xmlsec-dev \
            zlib-dev \
            git \
            curl \
            g++ \
            glib-dev \
            gawk \
            gnutls-dev \
            gpgme \
            libev-dev \
            libnl3-dev \
            libseccomp-dev \
            linux-headers \
            linux-pam-dev \
            lz4-dev \
            make \
            readline-dev \
            tar \
            xz \
            protobuf-c \
            protobuf-c-dev \
            gperf \
            apr \
            apr-dev \
	"; \
        set -x && \
      apk add --update --virtual .build-deps $buildDeps && \
      cd /tmp && \
      wget http://www.aleksey.com/xmlsec/download/xmlsec1-1.2.34.tar.gz && \
      tar xzf xmlsec1-1.2.34.tar.gz && \
      cd xmlsec1-1.2.34 && \
      ./configure --enable-soap && \
      make && \
      make install && \
      cd /tmp && \
      wget https://dev.entrouvert.org/releases/lasso/lasso-2.8.0.tar.gz && \
      tar zxf lasso-2.8.0.tar.gz && \
      cd lasso-2.8.0 && \
      ./configure && \
      make && \
      make install && \
      git clone https://gitlab.com/morganofbass/ocserv.git && \
      cd ocserv && \
      autoreconf -fvi && \
      ./configure --enable-saml-auth && \
      make && \
      make install && \
      runDeps="$( \
            scanelf --needed --nobanner /usr/local/sbin/ocserv \
            	| awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            	| xargs -r apk info --installed \
            	| sort -u \
            ) \
            gnutls-utils \
            iptables \
            xmlsec \
            libxml2 \
            rsync \
            sipcalc \
            libnl3 \
            certbot \
            bash" && \
      apk add --update --virtual .run-deps $runDeps && \
      apk del .build-deps && \
      rm -rf /var/cache/apk/* && \
      rm -rf /tmp/*

VOLUME /config

COPY ocserv /etc/default/ocserv

WORKDIR /ocserv

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443/tcp
EXPOSE 443/udp
EXPOSE 80/tcp
CMD ["ocserv", "-c", "/config/ocserv.conf", "-f"]
