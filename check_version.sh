#!/usr/bin/env bash
set -Eeu

readonly MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat ${MY_DIR}/docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

# Written down here so the gate fails when the floating base image moves to a
# different busted. Reading it from the image instead would compare the image
# against itself and pass whatever the move brought in.
readonly EXPECTED=2.3

# Asks the installed runner through the unversioned name a kata calls, so the
# gate fails both when the busted the image can run is not the one named above,
# and when the symlink carrying that name is missing. Matching on the leading
# major.minor lets a patch release through and stops only a minor or major move.
readonly ACTUAL=$(docker run --rm ${IMAGE_NAME} sh -c 'busted --version')

if echo "${ACTUAL}" | grep -q "${EXPECTED}"; then
  echo "VERSION CONFIRMED as ${EXPECTED}"
else
  echo "VERSION EXPECTED: ${EXPECTED}"
  echo "VERSION   ACTUAL: ${ACTUAL}"
  exit 42
fi
