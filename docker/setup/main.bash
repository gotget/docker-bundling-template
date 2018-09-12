#!/usr/bin/env bash
: <<'!COMMENT'

This script mostly sets up and tears down the installation process, and calls upon app/setup/main.bash in between.

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

export DEBIAN_FRONTEND="noninteractive"

function setupPrerequisites {

	apt-get update

} # END FUNCTION : setupPrerequisites

function cleanup {

	echo "Image size before clean-up: $( du -smh / 2>/dev/null | awk '{print $1}' )"

	apt-get autoremove --purge --yes > /dev/null 2>&1

	rm -rf \
		/usr/local/src/ \
		/var/lib/apt/lists/* \
		/tmp/* \
		>/dev/null 2>&1

	echo "Image size after clean-up: $( du -smh / 2>/dev/null | awk '{print $1}' )"

} # END FUNCTION : cleanup

# Move application into place
if [ -d /tmp/app/ ]; then
	shopt -s dotglob
	mv -v /tmp/app/* /usr/src/app/
	shopt -u dotglob
fi

setupPrerequisites

bash /usr/src/app/.dbt/setup/main.bash

cleanup

ldconfig
