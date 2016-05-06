ephemeral-npm
=============

A docker image to allow for testing of npm modules against a set of
other npm modules.

# Usage

    docker run -d -P -e npm_config_registry=$(npm config get registry) strongloop/ephemeral-npm

Copyright &copy; IBM Corp. 2015,2016. All Rights Reserved.
