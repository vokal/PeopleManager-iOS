#!/bin/bash

if [[ "$HOCKEYAPP_API_TOKEN" == "FIXME" ]] \
    || [[ "$ITUNES_CONNECT_ACCOUNT" == "FIXME" ]] \
    || [[ "$ITUNES_CONNECT_PASSWORD" == "FIXME" ]]; then
    echo "Go back and re-read the instructions."
    exit 1
fi

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
    echo "This is a pull request. No deployment will be done."
    exit 0
fi

# Make the (signed) build and IPA.
echo "========== Using shenzhen to make an IPA... =========="
if [ -n "$XC_WORKSPACE" ]; then
    bundle exec ipa build \
        --workspace "$XC_WORKSPACE" \
        --scheme "$XC_SCHEME" \
        --configuration "$XC_CONFIGURATION" \
        --sdk "iphoneos$SDK_VERSION"
else
    bundle exec ipa build \
        --project "$XC_PROJECT" \
        --scheme "$XC_SCHEME" \
        --configuration "$XC_CONFIGURATION" \
        --sdk "iphoneos$SDK_VERSION"
fi
if [ "$?" -ne 0 ]; then
    exit 1
fi

# If the environment has the HockeyApp credentials needed, then try to upload to HockeyApp.
if [ -n "$HOCKEYAPP_API_TOKEN" ]; then
    echo "========== Using shenzhen to upload the IPA to HockeyApp... =========="
    bundle exec ipa distribute:hockeyapp \
        --notes "This version was automatically uploaded by the continuous integration server." \
        --release beta \
        --dsym "$TRAVIS_BUILD_DIR/$APPNAME.app.dSYM.zip"
    if [ "$?" -ne 0 ]; then
        echo
        echo "error: Failed to upload to HockeyApp."
        exit 1
    fi
    echo
    echo "HockeyApp upload finished!"
fi

# If the environment has the iTunes Connect credentials needed, then try to upload to iTunes Connect.
if [ -n "$ITUNES_CONNECT_ACCOUNT" ] && [ -n "$ITUNES_CONNECT_PASSWORD" ]; then
    echo "========== Using shenzhen to upload the IPA to iTunes Connect... =========="
    bundle exec ipa distribute:itunesconnect \
        --apple-id "$ITUNES_CONNECT_APPLE_ID" \
        --upload
    if [ "$?" -ne 0 ]; then
        echo
        echo "error: Failed to upload to iTunes Connect"
        exit 1
    fi
    echo
    echo "iTunes Connect upload finished!"
fi
