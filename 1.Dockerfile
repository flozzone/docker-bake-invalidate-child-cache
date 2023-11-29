# syntax=docker/dockerfile:1
FROM quay.io/bashell/alpine-python:3

# comment following line out to make IDs of image2-A and image2-A match
COPY test-copy.txt test-copy.txt
