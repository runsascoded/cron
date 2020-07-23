# cron
Simple docker cron runner for easy persistence of runs, with docker-in-docker support for running Docker-based tasks

## Install
Install `cron.sh`, e.g. in `~/bin`:
```bash
# Install cron.sh, e.g. in `~/bin`:
bin="$HOME/bin" \
mkdir -p "$bin" && \
wget -O "$bin/cron.sh" https://j.mp/_cron && \
chmod u+x "$bin/cron.sh"
```

## Use
Call [`cron.sh`](cron.sh), by its absolute path, from your crontab:

```bash
echo "34 12 * * * $HOME/bin/cron.sh <dir>" | crontab
```

- `<dir>` should contain an executable `cron.sh` script that will be run on the cron schedule above.
- `<dir>` will be mounted into an outer "cron" Docker container at `/mnt`, and `/mnt/cron.sh` will be run
- {stdout,stderr} will be logged to /tmp/{out,err} (in the outer "cron" Docker container).
