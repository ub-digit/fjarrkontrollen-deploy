FROM node:16.20.2-bullseye

# Add the app's binaries path to $PATH
ENV PATH=/home/node/app/bin:$PATH

# Install global node dependencies and required packages
RUN set -ex \
  && npm install -g ember-cli@3.14.0 \
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

# Install development entrypoint
COPY docker/frontend/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

# Expose the app, test and live-reload ports
# 4200 devserver
# 7020 TestEm
# 35730 livereload
EXPOSE 4200 7020 35730

# Change user
USER node
