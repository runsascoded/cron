# cron
Simple docker cron runner for easy persistence of runs, with docker-in-docker support for running Docker-based tasks

## Install
Download [`cron.sh`] and make it executable:

```bash
curl https://j.mp/_cron > "$HOME/bin/cron.sh" && chmod u+x "$HOME/bin/cron.sh"
```

### As a submodule <a id="#install-submodule"></a>
Alternatively, clone this repo, or add it as a submodule of a project you intend to use it with:
```bash
git submodule add https://github.com/runsascoded/cron
```

## Use
Call [`cron.sh`] from your crontab, passing a directory you want to run a script from:

```bash
echo "34 12 * * * $HOME/bin/cron.sh <dir>" | crontab
```

- Call `cron.sh` by its absolute path, unless you install it somewhere that `crontab` will pick up, (e.g. `/usr/bin`, `/bin`)
- `<dir>` should contain an executable `run.sh` script that will be run on the cron schedule above
- `<dir>` will be mounted into an outer "cron" Docker container at `/mnt`, and `/mnt/run.sh` will be run
- {stdout,stderr} from running `<dir>/run.sh` (inside Docker, as `/mnt/run.sh`) will be logged to /tmp/{out,err} (in the outer "cron" Docker container)

### From a Git clone: `install.sh`
From a clone of this repo, `install.sh` can simplify adding the necessary line to your `crontab`:
```
install.sh "34 12 * * *" <dir>
```
where `<dir>` is the same as [above](#use).

If you've [added this repo as a submodule](#install-submodule) to the repo intended to be operated on, that repo will be inferred as the `<dir>` argument:

```bash
install.sh "34 12 * * *"
```

## Example
See [examples/hello-world/run.sh] for an example directory suitable to be passed to `cron.sh`.

To run it (from a clone of this repo):

### Install `crontab`
Append a cron.sh call to crontab:
```bash
(crontab -l 2>/dev/null; echo "* * * * * $PWD/cron.sh $PWD/examples/hello-world") | crontab
```

### Watch for Docker containers to appear
```bash
watch docker container ls -n 5
```

At the next minute mark, you should see a `hello-word-YYYYMMDDTHHMMSS` container (image `runsascoded/cron`) run. [This `hello-world` example][examples/hello-world/run.sh] in turn spawns a `hihi-YYYYMMDDTHHMMSS` container, so that should appear as well:

```
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS                          PORTS               NAMES
3b3f84389b04        hello-world         "/hello"                 44 seconds ago       Exited (0) 44 seconds ago                           hihi-20200722T235500
a907647148d7        runsascoded/cron    "/entrypoint.sh 2020…"   45 seconds ago       Exited (0) 43 seconds ago                           hello-world-20200722T235500
```

### Inspect stdout/stderr
stdout/stderr (from [examples/hello-world/run.sh]) can be viewed in the former container:
```bash
docker cp hello-world-20200722T235500:/tmp/err -
```

When I run this on macOS, I see a gibberish prefix due to `/tmp/err` being a file from a different OS/filesystem:
```
# err0100644000000000000000000000001413706205311007751 0ustar0000000000000000some stderr
```
but the true stderr ("`some stderr`") is visible at the end.

You can also shell into the container and view it cleanly in its natural environment:
```bash
docker commit hello-world-20200722T235500 tmp-image
docker run -it --entrypoint /usr/bin/env tmp-image bash
```
Then, in the container:
```bash
cat /tmp/err
# some stderr
```

### Uninstall from `crontab`
This task will keep running, each minute, generating 2 similar containers:
```
368f42e53a94        hello-world         "/hello"                 About a minute ago   Exited (0) About a minute ago                       hihi-20200722T235700
ce5e24a09cba        runsascoded/cron    "/entrypoint.sh 2020…"   About a minute ago   Exited (0) About a minute ago                       hello-world-20200722T235700
d5574b68990e        hello-world         "/hello"                 2 minutes ago        Exited (0) 2 minutes ago                            hihi-20200722T235601
3958a868bc6e        runsascoded/cron    "/entrypoint.sh 2020…"   2 minutes ago        Exited (0) 2 minutes ago                            hello-world-20200722T235601
3b3f84389b04        hello-world         "/hello"                 3 minutes ago        Exited (0) 3 minutes ago                            hihi-20200722T235500
a907647148d7        runsascoded/cron    "/entrypoint.sh 2020…"   3 minutes ago        Exited (0) 3 minutes ago                            hello-world-20200722T235500
```

When you've seen enough, remove the line we added from your crontab:
```bash
crontab -l | head -n -1 | crontab
```


[`cron.sh`]: cron.sh
[`install.sh`]: install.sh
[examples/hello-world/run.sh]: examples/hello-world/run