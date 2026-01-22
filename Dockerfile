ARG PHP_VERSION="8.5"
ARG ALPINE_VERSION="3.23"

#####

FROM php:${PHP_VERSION}-cli-alpine${ALPINE_VERSION} AS builder

ARG GITHUB_REP2_HASH="e5a5325"

RUN apk --update-cache add \
            git \
            patch \
            gettext-dev \
            jpeg-dev \
            libpng-dev \
            zlib-dev

RUN docker-php-ext-configure gd --with-jpeg
RUN docker-php-ext-install -j$(nproc) gd gettext

WORKDIR /tmp

COPY --from=composer/composer:2.9-bin /composer /usr/local/bin/composer

RUN curl -LO https://github.com/mikoim/p2-php/archive/${GITHUB_REP2_HASH}.zip
RUN unzip ${GITHUB_REP2_HASH}.zip
RUN rm -rf /var/www && mv p2-php-* /var/www

WORKDIR /var/www

COPY patch /tmp
RUN cp /tmp/composer.* . && composer install
RUN rm -r doc
RUN rm -rf `find . -name '.git*' -o -name 'composer.*'`
RUN patch -p1 < /tmp/p2-php.patch

RUN mv conf conf.orig && ln -s /ext/conf conf
RUN mv data data.orig && ln -s /ext/data data
RUN ln -s /ext/rep2/ic rep2/ic

#####

FROM php:${PHP_VERSION}-cli-alpine${ALPINE_VERSION} AS builder2

ARG CODEBERG_PX2C_HASH="08fb9fa157"  # Version 20250614

RUN apk --update-cache add \
    curl-dev \
    g++ \
    gnu-libiconv-dev \
    # gnutls-dev \
    openssl-dev \
    lua5.4-dev \
    make \
    patch

WORKDIR /root
RUN wget https://codeberg.org/NanashiNoGombe/proxy2ch/archive/${CODEBERG_PX2C_HASH}.tar.gz
RUN tar xzvf ${CODEBERG_PX2C_HASH}.tar.gz

WORKDIR /root/proxy2ch
COPY patch /tmp
RUN patch -p1 < /tmp/proxy2ch.patch
RUN make

#####

FROM php:${PHP_VERSION}-cli-alpine${ALPINE_VERSION} AS builder3

ARG GITHUB_H2O_HASH="a9ba592b904684b8d12e9a825e4a579c31999c2b" # 2026/01/19

RUN apk --update-cache add \
    build-base \
    cmake \
    git \
    libuv-dev \
    linux-headers \
    openssl \
    openssl-dev \
    perl \
    zlib-dev

WORKDIR /root
RUN git clone --depth 1 --revision ${GITHUB_H2O_HASH} --recursive --shallow-submodules https://github.com/h2o/h2o
WORKDIR /root/h2o
RUN cmake -S . -B build && cmake --build build

#####

FROM php:${PHP_VERSION}-cli-alpine${ALPINE_VERSION}
# LABEL org.opencontainers.image.authors="Abe Masahiro <pen@thcomp.org>" \
#     org.opencontainers.image.source="https://github.com/pen/docker-rep2"

RUN apk --no-cache add \
            sudo \
            gettext \
            libintl \
            libjpeg \
            libpng \
            perl-http-daemon \
            perl-lwp-useragent-determined \
            perl-yaml-tiny \
            runit \
            zlib \
            \
            # gnutls \
            libcurl \
            libstdc++ \
            lua5.4-libs

COPY --from=builder /usr/local /usr/local
COPY --from=builder /var/www   /var/www
COPY --from=builder2 /root/proxy2ch/proxy2ch /usr/local/bin/
# ref: cmake_install.cmake
COPY --from=builder3 /root/h2o/build/h2o /usr/local/bin/
COPY --from=builder3 /root/h2o/include /usr/local/include
COPY --from=builder3 /root/h2o/deps/picotls/include /usr/local/include
COPY --from=builder3 /root/h2o/deps/quicly/include /usr/local/include
COPY --from=builder3 /root/h2o/build/libh2o.pc /usr/local/lib/pkgconfig/
COPY --from=builder3 /root/h2o/build/libh2o-evloop.pc /usr/local/lib/pkgconfig/
COPY --from=builder3 /root/h2o/misc/h2olog /usr/local/bin/
COPY --from=builder3 /root/h2o/share/h2o/annotate-backtrace-symbols /usr/local/share/h2o/
COPY --from=builder3 /root/h2o/share/h2o/fastcgi-cgi /usr/local/share/h2o/
COPY --from=builder3 /root/h2o/share/h2o/fetch-ocsp-response /usr/local/share/h2o/
COPY --from=builder3 /root/h2o/share/h2o/kill-on-close /usr/local/share/h2o/
COPY --from=builder3 /root/h2o/share/h2o/setuidgid /usr/local/share/h2o/
COPY --from=builder3 /root/h2o/share/h2o/start_server /usr/local/share/h2o/
COPY --from=builder3 /root/h2o/share/h2o/ca-bundle.crt /usr/local/share/h2o/
COPY --from=builder3 /root/h2o/share/h2o/status/index.html /usr/local/share/h2o/status/
COPY rootfs /

VOLUME /ext
EXPOSE 80

CMD ["/etc/rc.entry"]
