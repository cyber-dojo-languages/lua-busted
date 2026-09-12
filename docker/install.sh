#!/bin/sh -eu

# Alpine packages busted once per lua version, as lua5.5-busted, and installs
# its runner as /usr/bin/busted-5.5. The base image resolves which lua it holds
# when it is built and records it, so the version is read from there rather
# than written down a second time here where it could drift from the
# interpreter the package has to match.
readonly LUA_MAJOR_MINOR=$(sed --quiet 's/.*"lua_major_minor":"\([0-9.]*\)".*/\1/p' /versions.json)
readonly LUA_VERSION=$(sed --quiet 's/.*"lua":"\([0-9.]*\)".*/\1/p' /versions.json)

if [ -z "${LUA_MAJOR_MINOR}" ]; then
  echo '/versions.json has no lua_major_minor property' >&2
  exit 1
fi

apk update

# Because the base image follows the newest stable lua, it can reach a version
# alpine has not packaged busted for yet. Then this fails with apk's own "no
# such package" and the build goes red, which is the honest outcome: a red
# build says so, where quietly falling back to an older lua would ship an
# image whose interpreter is not the one the base image reports.
apk add "lua${LUA_MAJOR_MINOR}-busted"

# The unversioned name a kata's cyber-dojo.sh calls.
ln --symbolic "/usr/bin/busted-${LUA_MAJOR_MINOR}" /usr/local/bin/busted

# Read by check_version.sh. The runner is asked for its version rather than the
# package index, so the number recorded is one the image can actually run, and
# running it here also proves busted loads under this lua before any kata does.
readonly BUSTED_VERSION=$(busted --version)
echo "{\"lua\":\"${LUA_VERSION}\",\"lua_major_minor\":\"${LUA_MAJOR_MINOR}\",\"busted\":\"${BUSTED_VERSION}\"}" > /versions.json

rm -rf /var/cache/apk/*
