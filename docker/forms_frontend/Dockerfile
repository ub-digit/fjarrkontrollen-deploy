ARG EMBER_VERSION=3.28.6
FROM node:14.21.3-bullseye
ARG EMBER_VERSION

# Add the app's binaries path to $PATH
ENV PATH=/home/node/app/bin:$PATH

WORKDIR /home/node

# Install global node dependencies and required packages
RUN set -ex \
  && npm install -g "ember-cli@${EMBER_VERSION}" \
  && npm install -g bower@1.8.8 \
  && npm install -g check-dependencies@1.1.1 \
  && git clone https://github.com/facebook/watchman.git -b v4.9.0 --depth 1 \
  && cd watchman \
  && ./autogen.sh \
  && CXXFLAGS="-Wno-error" ./configure --without-python \
  && make \
  && make install \
  && cd .. \
  && rm -R watchman \
  && mkdir /home/node/app \
  && chown node:node /home/node/app

WORKDIR /home/node/app

COPY docker/frontend/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
USER node
