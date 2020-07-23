#!/usr/bin/env bash

set -e

if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: $0 <cron schedule> [dir]" >&2
    exit 1
fi

schedule="$1"; shift
if [ $# -gt 0 ]; then
    dir="$1"; shift
else
    cwd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

echo "$schedule \"$cwd/cron.sh\" \"$dir\"" | crontab
echo "New crontab:"
crontab -l
