group "default" {
  targets = [ "image1", "image2"]
  # Uncomment next line to not export image2 to docker
  # targets = [ "image2"]
}

variable "TAG" {}

variable "CACHE_DIR" {
  default = "/tmp/docker-test-cache"
}

variable "CACHE_ARGS" {
  default = "mode=max"
}

target "image1" {
  context    = "."
  dockerfile = "1.Dockerfile"
  cache-to   = ["type=local,dest=${CACHE_DIR}/image1,${CACHE_ARGS}"]
  cache-from = ["type=local,src=${CACHE_DIR}/image1"]
  tags       = ["image1:${TAG}"]
}

target "image2" {
  context    = "."
  dockerfile = "2.Dockerfile"
  contexts   = {
    baseapp = "target:image1"
    # uncomment next line to set the baseapp image statically. in this case image2 ID stays the same
    #baseapp = "docker-image://alpine"
  }
  cache-to   = ["type=local,dest=${CACHE_DIR}/image2,${CACHE_ARGS}"]
  cache-from = ["type=local,src=${CACHE_DIR}/image2"]
  tags       = ["image2:${TAG}"]
}