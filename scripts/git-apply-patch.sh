#!/bin/bash -ex

pwd
ls git-cf-release

pushd $GIT_REPO_DIR
curl $PATCH_URL | git am
popd

mv $INPUT_DIR $OUTPUT_DIR
