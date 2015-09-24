#!/bin/bash

# Run the XcodeCoverage script to generate a code coverage report.
"${XCODE_COVERAGE_DIR}/getcov"

# Figure out where XcodeCoverage puts its results.
source ${XCODE_COVERAGE_DIR}/envcov.sh
LCOV_OUTPUT_DIR="${BUILT_PRODUCTS_DIR}/lcov"

if [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
    # Upload the non-PR coverage to cvr.vokal.io
    curl -F coverage=@"${LCOV_OUTPUT_DIR}/Coverage.info" \
        "https://cvr.vokal.io/coverage?token=${CVR_TOKEN}&commit=${TRAVIS_COMMIT}&removepath=${TRAVIS_BUILD_DIR}"

    # Zip up the lcov output directory for easier S3 (artifact) uploading.
    zip --quiet --recurse-paths "${TRAVIS_BUILD_DIR}/lcov" "${LCOV_OUTPUT_DIR}"

    # Exit successfully (so that the pull-request type uploading doesn't happen).
    exit 0
fi

# For PRs, we have to do some more fiddling to get the proper commit hash ($TRAVIS_COMMIT is the hash of a merge
# that Travis makes, not the hash of the last commit in the PR)...
LAST_PR_COMMIT="${TRAVIS_COMMIT_RANGE##*...}"
# ... and we have to split the repo slug to get repo owner and name.
REPO_OWNER="${TRAVIS_REPO_SLUG%%/*}"
REPO_NAME="${TRAVIS_REPO_SLUG##*/}"
# Let's put those into a URL query string fragment, to make the lines in this script shorter.
GIT_PARAMS="commit=${LAST_PR_COMMIT}&owner=${REPO_OWNER}&repo=${REPO_NAME}"
# Do the actual upload of PR coverage to cvr.vokal.io.
URL="https://cvr.vokal.io/coverage?${GIT_PARAMS}&removepath=${TRAVIS_BUILD_DIR}&ispullrequest=1"
curl -F coverage=@"${LCOV_OUTPUT_DIR}/Coverage.info" "${URL}"
