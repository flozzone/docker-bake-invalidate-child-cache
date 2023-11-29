#!/usr/bin/env bash

set -e

TEST_TAG=$1
export CACHE_DIR=/tmp/docker-test-cache2
RUN_DIR=/tmp/docker-test-run
BAKE_SRC=docker-bake.hcl

BUILDKIT_IMAGE="moby/buildkit:v0.12.3"
BUILDKIT_FLAGS='--debug'

mkdir -p $RUN_DIR

recreate_builder() {
  docker buildx rm builder
  docker buildx create --driver docker-container --driver-opt image=$BUILDKIT_IMAGE --buildkitd-flags $BUILDKIT_FLAGS --name builder --use
}

prune_cache() {
  rm -rf $CACHE_DIR
}

build() {
  local RUN_TAG=$1

  export TAG=$RUN_TAG
  docker buildx bake --file $BAKE_SRC --load --print &> $RUN_DIR/$RUN_TAG-bake.json
  docker buildx bake --file $BAKE_SRC --load
  docker logs buildx_buildkit_builder0 &> $RUN_DIR/$RUN_TAG-buildkitd.log
}

compare_image() {
  local IMAGE=$1

  local TESTA_ID=$(docker image ls --digests --format json $IMAGE:${TEST_TAG}-A | jq -r .ID)
  local TESTB_ID=$(docker image ls --digests --format json $IMAGE:${TEST_TAG}-B | jq -r .ID)

  if [ "$TESTA_ID" != "$TESTB_ID" ]; then
    echo "❌  $IMAGE:${TEST_TAG}-A and $IMAGE:${TEST_TAG}-B images are not the same"
  else
    echo "✅  $IMAGE:${TEST_TAG}-A and $IMAGE:${TEST_TAG}-B images are the same"
  fi
}

prune_cache
recreate_builder
build "${TEST_TAG}-A"
recreate_builder
build "${TEST_TAG}-B"

ls -1 $RUN_DIR/${TEST_TAG}-*

compare_image "image1"
compare_image "image2"

