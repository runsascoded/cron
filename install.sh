#!/usr/bin/env bash

set -e

declare -a ARGS
logs=1
unset name
while [ $# -gt 0 ]
do
    unset OPTIND
    unset OPTARG
    while getopts ":Ln:" opt
    do
      case "$opt" in
        L) logs= ;;
        n) name="$OPTARG" ;;
        *) ;;
      esac
    done
    shift $((OPTIND-1))
    ARGS+=("$1")
    shift
done

num=${#ARGS[@]}
if [ $num -eq 0 -o $num -gt 3 ]; then
    echo "Usage: $0 <cron schedule> [-n name] [-d dir] [-L] [args...]" >&2
    if [ $num -gt 0 ]; then
        echo "Extra args: $@" >&2
    else
        echo "Missing args" >&2
    fi
    exit 1
fi

schedule="${ARGS[0]}"; ARGS=("${ARGS[@]:1}")
cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ${#ARGS[@]} -gt 0 ]; then
    dir="$(cd "${ARGS[0]}" && pwd)"; ARGS=("${ARGS[@]:1}")
else
    basename="$(basename "$cwd")"

    if ! [ -f "$cwd/.git" ]; then #|| [ "$(cat "$cwd/.git")" != "gitdir: ../.git/modules/$basename" ]; then
        echo "WARN: cron dir $cwd not obviously a Git submodule; can't infer module to install"
        exit 10
    fi
    git_file="$(cat "$cwd/.git")"
    git_dir="${git_file#gitdir: }"
    if [ "$git_dir" == "$git_file" ]; then
        echo "Unrecognized Git file $cwd/.git: $git_file" >&2
        exit 20
    fi
    dir="${git_dir%/.git/modules/$basename}"
    if [ "$dir" == "$git_dir" ]; then
        echo "Unrecognized Git dir found in $cwd/.git: $git_file" >&2
        exit 20
    fi
    dir="$(cd "$cwd" && cd "$dir" && pwd)"
    echo "Installing module $dir"
fi

if ! [ -x "$dir/run.sh" ]; then
    echo "$dir/run.sh doesn't exist or isn't executable" >&2
    exit 100
fi

# Basic crontab line: schedule, run script (cron.sh), directory target
cmd="$schedule \"$cwd/cron.sh\""

# If a container basename was provided, pass it through
if [ -n "$name" ]; then
    cmd="$cmd -n \"$name\""
fi

# If the Docker executable is not on sh's usual $PATH (/usr/bin:/bin), pass its directory explicitly to cron.sh
docker_dir="$(dirname "$(which docker)")"
if [ "$docker_dir" != /usr/bin -a "$docker_dir" != /bin ]; then
    cmd="$cmd -x \"$docker_dir\""
fi

# Append directory-target positional arg
cmd="$cmd \"$dir\""

for arg in ${ARGS[@]}; do
    cmd="$cmd \"$arg\""
done

# Optionally log to cron.{out,err} in the target directory
if [ -n "$logs" ]; then
    cmd="$cmd >>\"$dir/cron.out\" 2>>\"$dir/cron.err\""
fi

(set +e; crontab -l 2>/dev/null; echo "$cmd") | crontab

echo "New crontab:"
crontab -l
