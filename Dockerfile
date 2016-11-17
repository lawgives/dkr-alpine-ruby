FROM alpine:3.4

# System Ruby will segfault with irb because Ruby was not
# compiled with readline-dev
#RUN apk update \
#  && apk upgrade \
#  && apk --update add \
#     ruby ruby-irb ruby-rake ruby-io-console ruby-bigdecimal \
#     libstdc++ tzdata bash \
#  && rm -rf /var/cache/apk/*

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
    && { \
        echo 'install: --no-document'; \
        echo 'update: --no-document'; \
    } >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.3
ENV RUBY_VERSION 2.3.2
ENV RUBY_DOWNLOAD_SHA256 8d7f6ca0f16d77e3d242b24da38985b7539f58dc0da177ec633a83d0c8f5b197
ENV RUBYGEMS_VERSION 2.6.8

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
# readline-dev vs libedit-dev: https://bugs.ruby-lang.org/issues/11869 and https://github.com/docker-library/ruby/issues/75
RUN set -ex \
    \
    && apk add --no-cache --virtual .ruby-builddeps \
        autoconf \
        bison \
        bzip2 \
        bzip2-dev \
        ca-certificates \
        coreutils \
        gcc \
        gdbm-dev \
        glib-dev \
        libc-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        linux-headers \
        make \
        ncurses-dev \
        openssl \
        openssl-dev \
        procps \
        readline-dev \
        ruby \
        tar \
        yaml-dev \
        zlib-dev \
    \
    && wget -O ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
    && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
    \
    && mkdir -p /usr/src/ruby \
    && tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
    && rm ruby.tar.gz \
    \
    && cd /usr/src/ruby \
    \
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
    && { \
        echo '#define ENABLE_PATH_CHECK 0'; \
        echo; \
        cat file.c; \
    } > file.c.new \
    && mv file.c.new file.c \
    \
    && autoconf \
# the configure script does not detect isnan/isinf as macros
    && ac_cv_func_isnan=yes ac_cv_func_isinf=yes \
        ./configure --disable-install-doc \
    && make -j"$(getconf _NPROCESSORS_ONLN)" \
    && make install \
    \
    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --virtual .ruby-rundeps $runDeps \
        bzip2 \
        ca-certificates \
        libffi-dev \
        openssl-dev \
        yaml-dev \
        procps \
        zlib-dev \
    && apk del .ruby-builddeps \
    && cd / \
    && rm -r /usr/src/ruby \
    \
    && gem update --system "$RUBYGEMS_VERSION"

RUN echo 'gem: --no-rdoc --no-ri' > /etc/gemrc

ENV BUNDLER_VERSION 1.13.6

RUN gem install bundler --version "$BUNDLER_VERSION" \
    && rm -r /root/.gem \
    && find / -name '*.gem' | xargs rm


CMD [ "irb" ]
