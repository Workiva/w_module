FROM google/dart:1.24.3 as build
WORKDIR /build/
ADD pubspec.* /build/
RUN pub get 
ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch
