#!/bin/bash

# Author: Robert McLeod
# Date:   16 August 2012
# Desc:	  Creates a user to be used for Braincase
# 		  This script will:
#			- use useradd to create a new user on the system
#			- create a bare git repository in the users home

# The usage message
function usage() {
	echo "Usage: create-braincase-user <name>";
	echo "\t- creates and sets up a user for Braincase";
}

# Check the current user is root
if [ "$UID" != 0 ]; then
	echo "You must be root to use this program.";
	exit 1;
fi;

# Print usage if requested
if [ "$1" = "-h" ];
	usage;
	exit 0;
fi;

# The new user
new_user=$1;
HOME="/home/$new_user";

# Verify that a user was given
if [ "$new_user" = "" ]; then
	echo "No username given.";
	usage;
	exit 1;
fi;

# Check if the user exists
user_exists="$(cat /etc/passwd|grep $new_user|wc -l)";
if [ "$user_exists" = "1" ]; then
	echo "User $new_user already exists";
	exit 1;
fi;

# Create the user
echo -n "Creating new Braincase user $new_user... ";
USERADD_OUTPUT=`useradd -m -d /home/$new_user $new_user 2>&1`;

# Check that all went well
if [ "$?" = "0" ]; then
	echo "done";
else
	echo "failed ($?):";
	echo $USERADD_OUTPUT;
	exit 1;
fi;

# Check if the repo exists
if [ -f "/home/$new_user/repo" ]; then
	echo "Repository already exists";
	exit 1;
fi;

# Create the repo
echo -n "Creating a personal repository for $new_user..."
SU_OUTPUT=`su $new_user -c "mkdir ~/repo && git init --bare ~/repo" 2>&1`;

# Check that all went well
if [ "$?" = "0" ]; then
	echo "done";
else
	echo "failed ($?):";
	echo $SU_OUTPUT;
	exit 1;
fi;

# Create the .braincase folder
if ! [ -f "$HOME/.braincase" ]; then
	mkdir "$HOME/.braincase";
fi;

echo
echo "Braincase user $new_user setup successfully.";
exit 0;