FROM alpine:latest
ENV METEOR_ALLOW_SUPERUSER=true


RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.26-r0" && \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
    apk --no-cache add --no-cache --virtual=.build-dependencies wget ca-certificates && \
    wget \
        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" \
        -O "/etc/apk/keys/sgerrand.rsa.pub" && \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    apk --no-cache add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    \
    apk del glibc-i18n && \
    \
    rm "/root/.wget-hsts" && \
    apk del .build-dependencies && \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

ENV LANG=C.UTF-8

WORKDIR /home/meteor

COPY known_hosts /home/meteor/.ssh/known_hosts

RUN apk  update && \
    apk  upgrade && \
    apk --no-cache add wget && \
    apk --no-cache add git && \
    apk --no-cache add curl && \
    apk --no-cache add libcap && \
    apk --no-cache add nodejs=8.9.1-r0 && \
    apk --no-cache add nodejs-npm=8.9.1-r0 && \
    cd ~ && \
    export PHANTOM_JS="phantomjs-2.1.1-linux-x86_64" && \
    wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2 && \
    mv $PHANTOM_JS.tar.bz2 /usr/local/share/ && \
    cd /usr/local/share/ && \
    tar xvjf $PHANTOM_JS.tar.bz2 && \
    ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/share/phantomjs && \
    ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/local/bin/phantomjs && \
    ln -sf /usr/local/share/$PHANTOM_JS/bin/phantomjs /usr/bin/phantomjs && \
    rm $PHANTOM_JS.tar.bz2 && \
    npm install -g semver && \
    setcap 'cap_net_bind_service=+ep' `which node`

COPY qc /home/meteor/src

RUN apk --no-cache add glib-dev glib gcc g++ make automake libuv libuv-dev http-parser http-parser-dev c-ares c-ares-dev openssl zlib zlib-dev gtest gtest-dev  && \
    cd /home/meteor && \
    (curl https://install.meteor.com/ | sh ) && \
    meteor create test --bare && \
    cd /home/meteor/test && meteor npm install && \
    cd /home/meteor/test && mv /home/meteor/test/.meteor/local  /home/meteor/src/.meteor/local && \
    cd /home/meteor/src && meteor npm install && \
    meteor npm install --save babel-runtime && \
    meteor npm install --save xmlhttprequest && \
    meteor remove accounts-password && \
    meteor npm uninstall bcrypt && \
    meteor npm install --save bcrypt && \
    meteor add accounts-password && \
    meteor npm install --save bcrypt && \
    meteor npm install --save meteor-node-stubs && \
    meteor npm install --save phantomjs-prebuilt && \
    mkdir -p /home/meteor/build && \
    meteor build --directory /home/meteor/build && \
    rm -rf /home/meteor/src && \
    rm -rf /home/meteor/test && \
    rm -rf /root/.meteor && \
    rm -rf /root/.npm && \
    apk  del git && \
    apk  del wget && \
    apk  del gnupg && \
    apk  del gnupg1 && \
    apk  del libcap && \
    apk  del glib gcc g++ make automake libuv-dev http-parser-dev c-ares-dev zlib-dev gtest-dev


COPY entrypoint.sh /home/meteor/entrypoint.sh
RUN  chmod +x /home/meteor/entrypoint.sh
RUN  mkdir /home/meteor/settings
COPY settings.json /home/meteor/settings
COPY settings_local.json /home/meteor/settings
COPY settings_dev.json /home/meteor/settings
COPY settings_beta.json /home/meteor/settings

EXPOSE 80

COPY docker-healthcheck /usr/local/bin/

ENTRYPOINT ["/home/meteor/entrypoint.sh"]
CMD []



