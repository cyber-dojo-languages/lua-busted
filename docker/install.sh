#!/bin/sh -eu

# Appends one test framework to the test_frameworks list the base image
# wrote in /versions.json, keeping any entry an earlier image added. Stops
# the build if the list is not found, rather than record nothing. Short grep
# flags because busybox grep has no long ones.
add_test_framework()
{
  name="${1}"
  version="${2}"
  entry="{\"name\": \"${name}\", \"version\": \"${version}\"}"
  if grep -q '"test_frameworks": \[\]' /versions.json; then
    sed -i "s|\"test_frameworks\": \[\]|\"test_frameworks\": [${entry}]|" /versions.json
  else
    sed -i "/\"test_frameworks\": \[/s|}\]|}, ${entry}]|" /versions.json
  fi
  if ! grep -q -F "${entry}" /versions.json; then
    echo "Could not add ${name} to /versions.json" >&2
    cat /versions.json >&2
    exit 1
  fi
}

# Alpine packages busted once per lua version, as lua5.5-busted, and installs
# its runner as /usr/bin/busted-5.5. The base image resolves which lua it holds
# when it is built and records it, so the version is read from there rather
# than written down a second time here where it could drift from the
# interpreter the package has to match.
readonly LUA_VERSION=$(sed --quiet '/"language"/,/}/s/.*"version": *"\([0-9.]*\)".*/\1/p' /versions.json)
readonly LUA_MAJOR_MINOR=$(echo "${LUA_VERSION}" | cut -d. -f1-2)

if [ -z "${LUA_MAJOR_MINOR}" ]; then
  echo '/versions.json has no language version' >&2
  cat /versions.json >&2
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

# The runner is asked for its version rather than the package index, so the
# number recorded is one the image can actually run, and running it here also
# proves busted loads under this lua before any kata does.
add_test_framework busted "$(busted --version)"
cat /versions.json

rm -rf /var/cache/apk/*
