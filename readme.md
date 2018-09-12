# Docker bundling template
> A template geared towards bundling applications with Docker, and deploying them to a server to be run by systemd via Docker Compose.

# Introduction

Please allow me to start by saying, if you haven't read [How We Deploy Python Code](https://www.nylas.com/blog/packaging-deploying-python/) on the [Nylas blog](https://www.nylas.com/blog), please take the time to do so, it's an excellent read that covers a common problem.

When deploying (usually, Python-based) programs, teammates and I have 1 of 3 choices, which vary based upon needs:

 1. [Docker Compose with systemd](https://github.com/docker/compose/issues/4266#issuecomment-302813256) - Daemons with less direct interfacing to a server.
 2. [dh-virtualenv](https://github.com/spotify/dh-virtualenv) - Daemons with more direct interfacing to a server (e.g. Network routes.)
 3. [Snappy](https://en.wikipedia.org/wiki/Snappy_(package_manager)) - Applications with more direct interfacing to a client (e.g. X11.)

For the purpose of this repository, the goal is #1: the higher-level needs may change, but the lower-level needs do not.  This is because I tend to use [systemd](**systemd**) and [Docker Compose](https://docs.docker.com/compose/) for running 1-n Docker containers, together as a multi-container application in a single file (e.g. [Tying MQTT, WebSockets, and Nginx together with Docker](https://thad.getterman.org/2017/09/04/tying-mqtt-websockets-and-nginx-together-with-docker)), or multiple Docker Compose-based applications independently, or together (e.g. running a Django application in a separate compose definition file that ties back to Nginx.)

# Usage

## Files to edit

In most cases, the only files that you'll need to edit are inside the `app/` directory:

 - `launch.bash` - Used for starting your program. You'll notice that the initial point in this file starts with `app/main.py`
 - `main.py` - Initial program included to demonstrate usage.  You can delete this program, and modify `launch.bash` to suit your needs.
 - `.dbt/` - Configuration for this repository, `Docker bundling template`
	 - `config.yaml` - Run and synchronization parameters for scripts to run.  Parameters are explained in the next section.
	 - `docker` - Used for modifying your run-time environment.
		 - `docker-compose-develop.yaml` - For developing.
		 - `docker-compose.yaml` - For deploying.
	 - `setup` - This entire directory relates to the setup and installation process required for your application.
		 - `main.bash` (optional) - Used for extending the installation process, and not a necessary edit.
		 - `modules.txt` - Python modules (1 per line.)
		 - `packages.txt` - System packages (1 per line.)

### `config.yaml` parameters:
 - `app` - Application settings used by various scripts.
	 - `container_name` - Name of your container (i.e. for direct calls via `docker` C.L.I. and what appears when you run `docker ps`)
	 - `image_name` - The name of your Docker image.
	 - `image_version` - The version of your Docker image.
	 - `run_service` - Which service in `docker-compose.yaml` and `docker-compose-develop.yaml` should be run.
 - `build` - used by `bin/build.bash`
	 - `clean` - attempt to remove *dangling* Docker images and *exited* containers after each build.
	 - `base` - Base of your Docker image.
		 - `image` - Which image to base off of (e.g. Ubuntu or CentOS.)
		 - `version` - For example, if you were using Ubuntu as your base image and wanted one of the recent [Long Term Support](https://wiki.ubuntu.com/LTS) versions, valid choices would be `16.04` or `18.04`.
 - `sync` (optional) - used by `bin/sync.bash` for live synchronization via SSH.
	 - `user` - remote username.
	 - `host` - remote host.
	 - `path` - remote path to synchronize to.

## Scripts to run

`bin/build.bash` - Used to build your Docker image, and has 2 modes to choose from via argument passed at command line:

 1. `bin/build.bash develop` (default) - Caches prerequisites, connects host volume to container, and drops you into a Bash shell.
 2. `bin/build.bash deploy` - Bundles everything together.

`bin/run.bash develop` (default) - Mostly used for developing, but good for checking your application's run for deployment (`bin/run.bash deploy`) on your remote server.

`bin/sync.bash` - useful for copying edits in real-time to a remote server, and developing (or deploying.)

# Authors/Contributors
* [Louis T. Getterman IV](https://Thad.Getterman.org/about)
* Have an improvement? Your name goes here!

> Written with [StackEdit](https://stackedit.io/).
