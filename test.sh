#!/usr/bin/env bash

set -e

TEST_TAG=$1
export CACHE_DIR=/tmp/docker-test-cache
RUN_DIR=/tmp/docker-test-run

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

  docker buildx bake --load

  # for debugging purpose
  docker buildx bake --load --print &> $RUN_DIR/$RUN_TAG-bake.json
  docker logs buildx_buildkit_builder0 &> $RUN_DIR/$RUN_TAG-buildkitd.log
  docker inspect image1:$RUN_TAG > $RUN_DIR/$RUN_TAG-image1-manifest.json
  docker inspect image2:$RUN_TAG > $RUN_DIR/$RUN_TAG-image2-manifest.json
}

compare_image() {
  local IMAGE=$1

  local TESTA_ID=$(docker inspect $IMAGE:${TEST_TAG}-A | jq -r '.[0].Id')
  local TESTB_ID=$(docker inspect $IMAGE:${TEST_TAG}-B | jq -r '.[0].Id')

  if [ "$TESTA_ID" != "$TESTB_ID" ]; then
    echo "❌  $IMAGE:${TEST_TAG}-A and $IMAGE:${TEST_TAG}-B have different image IDs"
  else
    echo "✅  $IMAGE:${TEST_TAG}-A and $IMAGE:${TEST_TAG}-B have same image IDs"
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

