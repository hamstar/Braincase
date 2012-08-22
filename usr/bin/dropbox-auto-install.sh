#!/bin/bash

# Author:	Robert McLeod
# Date:		20 August 2012
# Desc:		Automatically installs dropbox on a system by
#			downloading and installing the correct package
# 			and making sure its dependencies are met.

# checks that a url exists
function check_url() {
	
	wget --spider $1 -q
	if [ "$?" = "0" ]; then
	  echo "true";
	else
	  echo "false";
	fi;
}

function check_if_dropbox_installed() {
	# list packages					# ignore if only config files remain
	return `dpkg -l | grep dropbox | grep -v rc | wc -l`;
}

# Installs dropbox
function install_dropbox() {
	
	# Download the dropbox deb specified
	cd /tmp;
	wget $1;
	deb=`echo $1 | cut -d'/' -f6`;

	# Install it
	sudo dpkg -i $deb
	dropbox_installed_ok=$?;
	
	# Check if dropbox installed ok
	if [ "$dropbox_installed_ok" != 0 ]; then

		# It didn't... ask apt-get to install its dependencies for us
		echo "Oh dear thats not gone well, lets ask apt-get to install dependencies..."
		sudo apt-get install -fy;
		
		# try to run it again, hopefully dependancies are resolved now
		sudo dpkg -i $deb;
		dropbox_installed_ok=$?;
	fi;
	
	return $dropbox_installed_ok;
}

# Returns the architecture
function get_arch() {
	
	arch=`uname -m`;

	# i686 and i386 are compatible yet dropbox is only available in the latter
	if [ "$arch" = "i686" ]; then
	  arch="i386";
	fi

	echo $arch;
}

check_if_dropbox_installed;
if [ "$?" != 0 ] && [ "$1" != "-f" ]; then
	echo "Dropbox already installed (use -f to force install).";
	exit 0;
fi

# Build some vars
arch=`get_arch`;
deb_url="https://linux.dropbox.com/packages/debian/dropbox_1.4.0_$arch.deb";
deb_url_exists=`check_url $deb_url`;


# make sure the URL exists
if [ "$deb_url_exists" = "true" ]; then

	install_dropbox $deb_url; # it does so install dropbox

	# Check if the install worked
	if [ "$?" != "0" ]; then
		echo "Couldn't install dropbox, please try to do this manually if you want dropbox support on this system.";
		exit 1;
	fi;
else
	echo "Dropbox URL not found ($deb_url)"; # oh wrong url...?
	exit 1;
fi;

echo "Excellent, dropbox was installed successfully.";
exit 0;