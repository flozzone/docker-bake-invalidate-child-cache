#!/usr/bin/env bash

set -e

RUN_ID=$1
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
  docker inspect image1:$RUN_TAG > $RUN_DIR/$RUN_TAG-image1-manifest.json || true
  docker inspect image2:$RUN_TAG > $RUN_DIR/$RUN_TAG-image2-manifest.json

  unset TAG
}

compare_image() {
  local IMAGE=$1

  local TESTA_ID=$(jq -r '.[0].Id' $RUN_DIR/${RUN_ID}-A-${IMAGE}-manifest.json)
  local TESTB_ID=$(jq -r '.[0].Id' $RUN_DIR/${RUN_ID}-B-${IMAGE}-manifest.json)

  if [ "$TESTA_ID" == "null" ] || [ "$TESTB_ID" == "null" ]; then
    echo "⚠️  Cannot compare $IMAGE:${RUN_ID}-A and $IMAGE:${RUN_ID}-B"
    return
  fi

  if [ "$TESTA_ID" != "$TESTB_ID" ]; then
    echo "❌  $IMAGE:${RUN_ID}-A and $IMAGE:${RUN_ID}-B have different image IDs"
  else
    echo "✅  $IMAGE:${RUN_ID}-A and $IMAGE:${RUN_ID}-B have same image IDs"
  fi
}

export CACHE_DIR=$RUN_DIR/${RUN_ID}-cache
prune_cache

recreate_builder
build "${RUN_ID}-A"
recreate_builder
build "${RUN_ID}-B"

echo "Debug output:"
ls -1d $RUN_DIR/${RUN_ID}-*

echo "Compare output:"
compare_image "image1"
compare_image "image2"
