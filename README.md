# cron
Simple docker cron runner for easy persistence of runs, with docker-in-docker support for running Docker-based tasks

## Install
Download [`cron.sh`] and make it executable:

```bash
curl https://j.mp/_cron > "$HOME/bin/cron.sh" && chmod u+x "$HOME/bin/cron.sh"
```

(https://j.mp/_cron is just a bit.ly link to this repo's `master`-branch [`cron.sh`])

### As a submodule <a id="#install-submodule"></a>
Alternatively, clone this repo, or add it as a submodule of a project you intend to use it with:
```bash
git submodule add https://github.com/runsascoded/cron
```

## Use
Call [`cron.sh`] from your crontab, passing a "module" directory you want to run:

```bash
echo "34 12 * * * $HOME/bin/cron.sh <dir>" | crontab
```

Notes:
- Call `cron.sh` by its absolute path, unless you install it somewhere that `crontab` will pick up (`/usr/bin`, `/bin`)
- `<dir>` should contain an executable `run.sh` script that will be run on the cron schedule above
- `<dir>` will be mounted into an outer Docker container at `/mnt`, and `/mnt/run.sh` will be run each time the cron schedule fires
- the outer Docker container will be named like `<name>-YYYYMMDDTHHMMSS`, where `<name>` is an optional second argument to `cron.sh` in the crontab above; by default, the basename of `<dir>` will be used

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

### Schedule `crontab`
Append a `cron.sh` call to crontab, calling [examples/hello-world/run.sh] every minute:

```bash
./install.sh "* * * * *" examples/hello-world
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

### Inspect logs
Pull the outer container's logs :
```bash
docker logs hello-world-20200722T235500
```
```
some stdout
Fri Jul 24 04:03:00 UTC 2020
some stderr

Hello from Docker!
…
```

### Inspect stdout/stderr on host
By default, `install.sh` configures `cron.sh` to write its stdout/stderr to `<dir>/cron.{out,err}`; you can see this by inspecting the generated crontab, which might look something like:

```
* * * * * "<cron>/cron.sh" -x "/usr/local/bin" "<cron>/examples/hello-world" >>"<cron>/examples/hello-world/cron.out" 2>>"<cron>/examples/hello-world/cron.err"
```

Passing `-L` to `install.sh` disables this behavior.

### Inspect changed file on host
In addition to writing the stdout/stderr viewable above, [examples/hello-world/run.sh] appends the date to `examples/hello-world/msgs` each time it runs:

```bash
cat examples/hello-world/msgs
```
```
Ran at 20200722T235500
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