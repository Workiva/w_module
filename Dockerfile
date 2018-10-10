FROM google/dart:1.24.3 as build

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
		pub run dart_dev test --pub-serve --web-compiler=dartdevc -p chrome -p vm && \
		echo "Script sections completed"
ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch
