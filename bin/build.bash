#!/usr/bin/env bash
: <<'!COMMENT'

This script is used to build your Docker image, and has two modes:

[ develop ]
Caches your system packages (and by default, Python modules).
Using bin/run.bash, assuming you have not changed "command" in docker-compose-develop.yaml, will link your application and dump you into a Bash prompt.
You can repeatedly edit your application (and environment), and when ready, use "bin/build.bash deploy"

[ deploy ]
Bundles everything together.  You can then export and import the built Docker image to remote destinations (tools coming soon.)
Optionally, you can use bin/sync.bash to move this entire directory to your destination server, then run "bin/build.bash deploy" on it.

!COMMENT

################################################################################
SOURCE="${BASH_SOURCE[0]}" # Dave Dopson, Thank You! - http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	SCRIPTPATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$SCRIPTPATH/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
################################################################################
SCRIPTPATH="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
SCRIPTNAME=`basename "$SOURCE"`
################################################################################

# To-do: add error checking
# set -o errexit

# Additional paths
export BASEPATH="$( cd -P "${SCRIPTPATH}/../" && pwd )"
export APPPATH="$( cd -P "${SCRIPTPATH}/../app/" && pwd )"
export DBTPATH="${APPPATH}/.dbt/"

# Parse YAML
source "${SCRIPTPATH}/.support.bash"
eval $( parse_yaml "${DBTPATH}/config.yaml" )

# Environment variables for Docker (Compose)
export dockerBuildImage="${app_image_name}"
export dockerBuildVersion="${app_image_version}"
export dockerContainerName="${app_container_name}"
export dockerImage="${build_base_image}"
export dockerVersion="${build_base_version}"

# Select Mode
[[ $1 = "deploy" ]] && mode="$1" || mode="develop"

echo "Build mode : $mode"
echo "^C to abort"
sleep 2

# Create bundle : Deploy
if [ "$mode" == "deploy" ]; then

	export dockerFileBuild="Dockerfile-deploy"
	composeFileSuffix=""

	echo "Bundling Docker and Application includes..."
	cd "${BASEPATH}"

	# Avoid OS X files being added to the archive
	# https://unix.stackexchange.com/questions/282055/a-lot-of-files-inside-a-tar
	export COPYFILE_DISABLE=1

	tar \
		--exclude '.DS_Store' \
		-cvf "${BASEPATH}/bundle.tar" \
		./docker/setup/ \
		./app/ \
		;

# Create bundle : Develop
else

	export dockerFileBuild="Dockerfile-develop"
	composeFileSuffix="-develop"

fi

# Build image
echo "Docker Compose building image..."
docker-compose \
	--file "${DBTPATH}/docker/docker-compose${composeFileSuffix}.yaml" \
	build \
	;

# Clean bundle
if [ -f "${BASEPATH}/bundle.tar" ]; then

	echo -n "Removing bundle : "
	rm -rfv "${BASEPATH}/bundle.tar"

fi

# Clean Docker
if [ "${build_clean^^}" == "TRUE" ]; then

	echo -n "Cleaning Docker..."

	( docker rm $(docker ps --all --quiet --no-trunc --filter 'status=exited') ) >/dev/null 2>&1
	( docker rmi $(docker images --quiet --filter 'dangling=true') ) >/dev/null 2>&1

	echo "Done."

fi
