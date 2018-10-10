FROM google/dart:1.24.3 as build

RUN apt-get update -qq
RUN apt-get update && apt-get install -y \
        build-essential \
        curl \
        git \
        make \
        xvfb \
        wget \
        && rm -rf /var/lib/apt/lists/*

# install chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
        echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list && \
        apt-get -qq update && apt-get install -y google-chrome-stable && \
        mv /usr/bin/google-chrome-stable /usr/bin/google-chrome && \
        sed -i --follow-symlinks -e 's/\"\$HERE\/chrome\"/\"\$HERE\/chrome\" --no-sandbox/g' /usr/bin/google-chrome && \
        google-chrome --version

# Build Environment Vars
ARG BUILD_ID
ARG BUILD_NUMBER
ARG BUILD_URL
ARG GIT_COMMIT
ARG GIT_BRANCH
ARG GIT_TAG
ARG GIT_COMMIT_RANGE
ARG GIT_HEAD_URL
ARG GIT_MERGE_HEAD
ARG GIT_MERGE_BRANCH
WORKDIR /build/
ADD . /build/
RUN echo "Starting the script sections" && \
		pub get --packages-dir && \
		xvfb-run -s '-screen 0 1024x768x24' pub run dart_dev test --pub-serve --web-compiler=dartdevc -p chrome -p vm && \
		echo "Script sections completed"
ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch
