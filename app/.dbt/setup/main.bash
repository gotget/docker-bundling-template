#!/usr/bin/env bash
: <<'!COMMENT'

This script is used to handle the installation process via configuration files:

	* packages.txt - for the system
	* modules.txt  - for the Python modules

Upon completion, clean up the programs installation directory (app/setup/)

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

function installs {

	# Install system packages
	# Thanks: https://askubuntu.com/questions/252734/apt-get-mass-install-packages-from-a-file
	xargs --arg-file=<(awk '! /^ *(#|$)/' "${SCRIPTPATH}/packages.txt") --no-run-if-empty -- apt-get install --yes

	# Install Python modules
	pip install --no-cache-dir --requirement "${SCRIPTPATH}/modules.txt"

} # END FUNCTION : installs

function cleanup {

	rm -rf \
		"${SCRIPTPATH}" \
		>/dev/null 2>&1

} # END FUNCTION : cleanup

installs

cleanup
