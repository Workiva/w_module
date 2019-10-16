FROM google/dart:2.4 as dart2
# Build Environment Vars
ARG GIT_SSH_KEY
ARG KNOWN_HOSTS_CONTENT

RUN mkdir /root/.ssh
RUN echo "$KNOWN_HOSTS_CONTENT" > "/root/.ssh/known_hosts"
RUN echo "$GIT_SSH_KEY" > "/root/.ssh/id_rsa"
RUN chmod 700 /root/.ssh/
RUN chmod 600 /root/.ssh/id_rsa

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

RUN echo "Starting the script sections"
RUN eval "$(ssh-agent -s)" && ssh-add /root/.ssh/id_rsa

RUN pub get
RUN pub run dart_dev test

FROM scratch
