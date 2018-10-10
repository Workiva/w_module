FROM google/dart:1.24.3 as build

RUN apt-get update -qq
RUN apt-get update && apt-get install -y \
	build-essential \
	wget \
	&& rm -rf /var/lib/apt/lists/*

# install chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
	echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list && \
	apt-get -qq update && apt-get install -y google-chrome-stable && \
	mv /usr/bin/google-chrome-stable /usr/bin/google-chrome && \
	sed -i --follow-symlinks -e 's/\"\$HERE\/chrome\"/\"\$HERE\/chrome\" --no-sandbox/g' /usr/bin/google-chrome && \
	google-chrome --version


WORKDIR /build

# setup ssh
ARG GIT_SSH_KEY
ARG KNOWN_HOSTS_CONTENT
RUN mkdir /root/.ssh/ && \
  echo "$KNOWN_HOSTS_CONTENT" > "/root/.ssh/known_hosts" && \
  chmod 700 /root/.ssh/ && \
  umask 0077 && echo "$GIT_SSH_KEY" >/root/.ssh/id_rsa && \
  eval "$(ssh-agent -s)" && ssh-add /root/.ssh/id_rsa

# grab source
COPY . /build/

# deps / test / sanity check / build
ENV DART_FLAGS="--checked"
ARG BUILD_ID
ARG GIT_COMMIT
ARG GIT_TAG
ARG GIT_BRANCH
ARG GIT_MERGE_HEAD
ARG GIT_MERGE_BRANCH
RUN pub get --packages-dir && \
	pub run dart_dev test --pub-serve --web-compiler=dartdevc -p chrome -p vm
ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch
