#!/usr/bin/env bash
: <<'!COMMENT'

This script is used to export your built Docker image for deploying to remote locations without needing to build the image there.

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
saveFilePath="${BASEPATH}/app.tar"

# Parse YAML
source "${SCRIPTPATH}/.support.bash"
eval $( parse_yaml "${DBTPATH}/config.yaml" )

echo "Build (or use cache) : deploy"
bash "${SCRIPTPATH}/build.bash" "deploy";

# Save built Docker image to an archive, and attempt to show a progress bar and status box.
if hash pv 2>/dev/null && hash dialog 2>/dev/null; then

	(
	docker save "${app_image_name}":"${app_image_version}" \
		| \
			pv \
				--size `docker image inspect "${app_image_name}":"${app_image_version}" --format='{{.Size}}'` \
				-n \
				-f \
				>"${saveFilePath}"
	) 2>&1 \
		| \
			dialog --gauge "Exporting Docker image..." 11 80 \
	;
	sleep 0.5 | dialog --gauge "Exporting Docker image..." 11 80 100;
	dialog --infobox "File saved to:\n\n${saveFilePath}\n\nYou can import this image on a remote server (directly or via Ansible) by using the following command:\n\ndocker load --input app.tar" 11 80

else

	echo -n "Exporting Docker image..."
	docker save --output "${saveFilePath}" "${app_image_name}":"${app_image_version}"
	echo "Done."
	echo "-------------------------------------------------------------------------------"
	echo;
	echo "File saved to:"
	echo;
	echo ${saveFilePath}
	echo;
	echo "You can import this image on a remote server (directly or via Ansible) by using the following command:"
	echo;
	echo "docker load --input app.tar"
	echo;
	echo "-------------------------------------------------------------------------------"

fi
