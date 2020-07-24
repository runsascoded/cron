#!/usr/bin/env bash
#
# Call this script from your crontab, passing a directory you want to run a script from:
#
# ```bash
# echo "34 12 * * * $HOME/bin/cron.sh <dir> [name]" | crontab
# ```
#
# - Call `cron.sh` by its absolute path, unless you install it somewhere that `crontab` will pick up, (e.g. `/usr/bin`, `/bin`)
# - `<dir>` should contain an executable `run.sh` script that will be run on the cron schedule above
# - `<dir>` will be mounted into an outer "cron" Docker container at `/mnt`, and `/mnt/run.sh` will be run
# - {stdout,stderr} from running `<dir>/run.sh` (inside Docker, as `/mnt/run.sh`) will be logged to /tmp/{out,err} (in the outer "cron" Docker container)

set -e

declare -a ARGS
name=
pull=
extra_path=()
while [ $# -gt 0 ]
do
    unset OPTIND
    unset OPTARG
    while getopts ":n:px:" opt
    do
      case "$opt" in
        n) name="$OPTARG" ;;
        p) pull=1 ;;
        x) extra_path+=("$OPTARG") ;;
        *) ;;
      esac
    done
    shift $((OPTIND-1))
    ARGS+=("$1")
    shift
done

for dir in ${extra_path[@]}; do
    PATH="$PATH:$dir"
done

now="$(date '+%Y%m%dT%H%M%S')"

# Passed in directory will be mounted in outer Docker under /mnt, and /mnt/run.sh will be run

if [ ${#ARGS[@]} -eq 0 ]; then
    echo "Usage: $0 [-p(ull)] [-n name] [-x path]* <dir> [args...]" >&2
    exit 1
fi

dir="$(cd "${ARGS[0]}" && pwd)"
ARGS=("${ARGS[@]:1}")

if [ -z "$name" ]; then
    name="$(basename "$dir")"
fi

docker run \
    --name "$name-$now" \
    -v "/var/run/docker.sock:/var/run/docker.sock" \
    -v "$dir:/mnt" \
    runsascoded/cron \
    "$now" \
    ${ARGS[@]}
