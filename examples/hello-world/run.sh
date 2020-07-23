#!/usr/bin/env bash

set -e

# {stdout,stderr} get logged to /tmp/{out,err} inside the "cron" Docker container
echo some stdout
date
echo some stderr >&2

# The outer container's run-start time is passed as an argument:
now="$1"; shift

# Append to a local file path, which will show up in the mounted dir (outside the `cron` container)
echo "Ran at $now" >> msgs

# Running Docker containers works!
docker run --name "hihi-$now" hello-world
