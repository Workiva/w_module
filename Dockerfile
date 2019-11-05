FROM drydock-prod.workiva.net/workiva/dart2_base_image:1
WORKDIR /build/
ADD . /build/

RUN echo "Starting the script sections"
RUN pub get
## TODO: Add `--coverage` when it becomes available
RUN pub run dart_dev test

FROM scratch
