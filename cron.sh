#!/usr/bin/env bash -l
#
# Call this script, by its absolute path, from your crontab, e.g.:
#
# mkdir -p "$HOME/bin" && wget -O "$HOME/bin/cron.sh" https://j.mp/_cron && chmod u+x "$HOME/bin/cron.sh"
# echo "34 12 * * * /bin/cron.sh <dir>" | crontab
#
# - <dir> should contain an executable `cron.sh` script that will be run on the cron schedule above.
# - It will be mounted into an outer "cron" Docker container at /mnt, and /mnt/cron.sh will be run
# - {stdout,stderr} will be logged to /tmp/{out,err} in the outer "cron" Docker container.

set -e

if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: $0 <dir> [name]" >&2
    exit 1
fi

# Passed in directory will be mounted in outer Docker under /mnt, and /mnt/cron.sh will be run
dir="$1"; shift
name"$1"; shift
if [ -z "$name" ]; then
    name="$(basename "$dir")-$(date '+%Y%m%dT%H%M%S')"
fi

docker run \
    --name "$name" \
    -v "$(which docker):/bin/docker" \
    -v "/var/run/docker.sock:/var/run/docker.sock" \
    -v "$dir:/mnt" \
    runsascoded/cron
