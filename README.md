ephemeral-npm
=============

A docker image to allow for testing of npm modules against a set of
other npm modules.

# Usage

    docker run -d -P -e npm_config_registry=$(npm config get registry) strongloop/ephemeral-npm

&copy; 2015 StrongLoop, Inc.
