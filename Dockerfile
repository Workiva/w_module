FROM drydock.workiva.net/workiva/dart_unit_test_image:1

RUN apt-get update && apt-get install -y \
        # xvfb is used to run browser tests headless
        xvfb \
        && rm -rf /var/lib/apt/lists/*

RUN xvfb-run -s '-screen 0 1024x768x24' pub run test -p chrome --coverage=cov
RUN pub global activate coverage
RUN pub global run coverage:format_coverage -l -i cov -o lcov
ARG BUILD_ARTIFACTS_CODECOV=/build/lcov

FROM scratch