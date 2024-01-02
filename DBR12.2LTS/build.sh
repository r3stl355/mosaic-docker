#!/bin/bash

set -e

docker buildx build -t "mosaic-dev:dbr12.2LTS-spark3.3.2-amd64" --progress=plain --platform linux/amd64 --load .
docker buildx build -t "mosaic-dev:dbr12.2LTS-spark3.3.2-arm64" --progress=plain --platform linux/arm64 --load .
