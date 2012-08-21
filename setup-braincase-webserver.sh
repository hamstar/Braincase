#!/bin/bash

# Author: Bhavic Patel
# Date:   20 August 2012
# Desc:	  Sets up Apache2 which will be used by Braincase
# 		  This script will:
#			- Install Apache2 from Debian Repo
#			- Setup per-user web homes

# The usage message
function usage() {
	echo "Usage: ./$0 ";
}

function enableUserDir() {
a2enmod userdir
sed -i.bak 's/public_html/webdir/g' /etc/apache2/mods-enabled/userdir.conf  #Change folder to webdir

/etc/init.d/apache2 restart
}
# Check the current user is root
if [ "$UID" != 0 ]; then
	echo "You must be root to use this program.";
	exit 1;
fi

# Print usage if requested
if [ "$1" = "-h" ]; then
	usage;
	exit 0;
fi

# Verify Apache2 isn't already installed
if [ -d /etc/apache2 ]; then
	echo  "It seems Apache2 is already installed!... Exiting";
	exit 1;
fi


## Install Apache2
#Clean
echo -n "Cleaning apt-get cache... ";
apt-get clean -qq 2>&1
if [ $? = "1" ]; then
	echo -n "There was a error installing Apache. Error printed below";
	exit
fi
echo  "done ";

#Update
echo -n "Updating apt-get repo... ";
apt-get update -qq 2>&1
if [ $? = "1" ]; then
	echo -n "There was a error installing Apache. Error printed below";
	exit
fi
echo  "done ";

#Install
echo -n "Installing Apache2... ";
INSTALL_OUTPUT=`apt-get install -qq -f apache2 2>&1`


if [ $? = "1" ]; then
	echo -n "There was a error installing Apache. Error printed below";
	echo -n $INSTALL_OUTPUT;
	exit 1;
else
   echo  "done ";
fi

#Enable per-user mod




echo "Braincase webserver setup sucessfully";
exit 0;