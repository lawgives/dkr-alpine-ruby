# `alpine-ruby`: Minimal Ruby image

This is based on `cybercode/alpine-ruby:2.2`

This is a small MRI Ruby 2.3 image. It uses the [Alpine Linux](https://www.alpinelinux.org) ruby packages, and has `bundler` and minimal ruby packages installed.

## Building

```
make
```

To push

```
make push
```

## Using this package

``` Dockerfile
FROM legalio/alpine-ruby:2.3
CMD["/mycommand"]
```

Unlike the [Official Ruby Image](https://hub.docker.com/_/ruby/) or [tinycore-ruby](https://hub.docker.com/r/tatsushid/tinycore-ruby/), it does not create any users or do `ONBUILD` magic and the `CMD` defaults to `irb`.

### Using C-based gems

This image does not contain a compiler, etc. The best way to install C-based gems is to install the compiler chain and any development libraries required, run bundle install and remove the libraries all in one `RUN` command. That way the the final image will stay small.

For example,  if you are using the `pg` and `nokogiri` gems:

``` Dockerfile
RUN apk --update add --virtual build_deps \
    build-base ruby-dev libc-dev linux-headers \
    openssl-dev postgresql-dev libxml2-dev libxslt-dev && \
    sudo -iu app bundle config build.nokogiri --use-system-libraries && \
    sudo -iu app bundle install --path vendor/bundle && \
    apk del  build_deps
```
