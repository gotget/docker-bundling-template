#!/usr/bin/env bash
: <<'!COMMENT'

This script is used to run your application, specifically, Docker container, and has two modes:

[ develop ]
Useful for local development (in my case, OS X) with focus on docker/docker-compose-develop.yaml (you should edit this file) from Dockerfile-develop (you should not have to edit this file.)

[ deploy ]
Useful for remote deployment (in my case, Ubuntu Server) with focus on docker/docker-compose.yaml (you should edit this file) pulling from Dockerfile-deploy (you should not have to edit this file.)

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

if [ "$1" == "develop" ] || [ "$1" == "deploy" ]; then
	shift;
fi

echo "Run mode : $mode"
echo "^C to abort"
sleep 2

echo "Build (or use cache) : ${mode}"
bash "${SCRIPTPATH}/build.bash" "${mode}";

# Create bundle : Deploy
if [ "$mode" == "deploy" ]; then

	export dockerFileBuild="Dockerfile-deploy"
	composeFileSuffix=""

# Create bundle : Develop
else

	export dockerFileBuild="Dockerfile-develop"
	composeFileSuffix="-develop"

fi

echo "Running '${app_run_service}'"
docker-compose \
		--file "${DBTPATH}/docker/docker-compose${composeFileSuffix}.yaml" \
		run "${app_run_service}" $* \
		;

echo -n "Tear-down..."
docker-compose \
		--file "${DBTPATH}/docker/docker-compose${composeFileSuffix}.yaml" \
		down \
		>/dev/null 2>&1 &
echo "Done!"
