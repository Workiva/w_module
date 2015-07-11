#!/bin/bash

dartanalyzer --fatal-warnings --no-hints \
    lib/*.dart \
    test/*.dart \
    example/web/*.dart \
    example/lib/src/panel/*.dart
