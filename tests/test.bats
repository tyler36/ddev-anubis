#!/usr/bin/env bats

# Bats is a testing framework for Bash
# Documentation https://bats-core.readthedocs.io/en/stable/
# Bats libraries documentation https://github.com/ztombol/bats-docs

# For local tests, install bats-core, bats-assert, bats-file, bats-support
# And run this in the add-on root directory:
#   bats ./tests/test.bats
# To exclude release tests:
#   bats ./tests/test.bats --filter-tags '!release'
# For debugging:
#   bats ./tests/test.bats --show-output-of-passing-tests --verbose-run --print-output-on-failure

setup() {
  set -eu -o pipefail

  # Override this variable for your add-on:
  export GITHUB_REPO=tyler36/ddev-anubis

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-$(basename "${GITHUB_REPO}")"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  cp "${DIR}/tests/testdata/index.php" "${TESTDIR}/index.php"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  export CI=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}" --project-tld=ddev.site
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  run curl -skI --max-time 10 "https://${PROJNAME}.ddev.site"
  assert_success
  # Assert the website is accessible.
  assert_output --partial "HTTP/2 200"
  assert_output --partial "test_header"
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1
  # Persist TESTDIR if running inside GitHub Actions. Useful for uploading test result artifacts
  # See example at https://github.com/ddev/github-action-add-on-test#preserving-artifacts
  if [ -n "${GITHUB_ENV:-}" ]; then
    [ -e "${GITHUB_ENV:-}" ] && echo "TESTDIR=${HOME}/tmp/${PROJNAME}" >> "${GITHUB_ENV}"
  else
    [ "${TESTDIR}" != "" ] && rm -rf "${TESTDIR}"
  fi
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

@test "routes requests through Anubis" {
  set -eu -o pipefail

  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks

  run docker stop "ddev-${PROJNAME}-anubis"
  assert_success
  run curl -skS --max-time 10 -o /dev/null -w '%{http_code}' "https://${PROJNAME}.ddev.site"
  request_exit_status="$status"
  response_code="$output"
  run docker start "ddev-${PROJNAME}-anubis"
  assert_success
  assert_equal 0 "$request_exit_status"
  if [[ ! "$response_code" =~ ^5[0-9]{2}$ ]]; then
    printf "Expected a 5xx response with Anubis stopped, got %s\n" "$response_code" >&2
    return 1
  fi
}

@test "Custom port can be set" {
  set -eu -o pipefail

  export TEST_ANUBIS_PORT="8123"
  ddev dotenv set .ddev/.env.anubis --anubis-port=${TEST_ANUBIS_PORT}
  run ddev restart -y

  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success

  # Check Traefik config contains the Anubis backend service.
  run grep -Fq "${PROJNAME}-anubis-${TEST_ANUBIS_PORT}" .ddev/traefik/config/ddev-anubis.yaml
  assert_success

  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
