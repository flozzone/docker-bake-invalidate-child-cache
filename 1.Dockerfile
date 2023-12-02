# syntax=docker/dockerfile:1
FROM alpine:3.18.4

# comment following line out to make IDs of image2-A and image2-A match
COPY test-copy.txt test-copy.txt

# a run command doesn't affect caching of child target
#RUN apk add bash
