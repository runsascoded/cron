#!/usr/bin/env bash
#
# Call this script from your crontab, passing a directory you want to run a script from:
#
# ```bash
# echo "34 12 * * * $HOME/bin/cron.sh <dir>" | crontab
# ```
#
# - Call `cron.sh` by its absolute path, unless you install it somewhere that `crontab` will pick up, (e.g. `/usr/bin`, `/bin`)
# - `<dir>` should contain an executable `run.sh` script that will be run on the cron schedule above
# - `<dir>` will be mounted into an outer "cron" Docker container at `/mnt`, and `/mnt/run.sh` will be run
# - {stdout,stderr} from running `<dir>/run.sh` (inside Docker, as `/mnt/run.sh`) will be logged to /tmp/{out,err} (in the outer "cron" Docker container)

set -e

if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: $0 <dir> [name]" >&2
    exit 1
fi

now="$(date '+%Y%m%dT%H%M%S')"
# Passed in directory will be mounted in outer Docker under /mnt, and /mnt/run.sh will be run
dir="$(cd "$1" && pwd)"; shift
if [ $# -gt 0 ]; then
    name="$1"; shift
else
    name="$(basename "$dir")-$now"
fi

docker run \
    --name "$name" \
    -v "/var/run/docker.sock:/var/run/docker.sock" \
    -v "$dir:/mnt" \
    runsascoded/cron \
    "$now" \
    "$@"
