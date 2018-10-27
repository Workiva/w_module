FROM google/dart:1.24.3 as build

COPY pubspec.* /build/
RUN pub get 
ARG BUILD_ARTIFACTS_BUILD=/build/pubspec.lock
FROM scratch
