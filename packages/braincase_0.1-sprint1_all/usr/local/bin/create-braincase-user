#!/bin/bash

new_user=$1;

if [ "$new_user" = "" ]; then
	echo "No username given";
	exit 1;
fi

# Check if the user exists
user_exists="$(cat /etc/passwd|grep $new_user|wc -l)";
if [ "$user_exists" = "1" ]; then
	echo "User $new_user already exists";
	exit 1;
fi

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
fi

# Check if the repo exists
if [ -f "/home/$new_user/repo" ]; then
	echo "Repository already exists";
	exit 1;
fi

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
fi

echo
echo "Braincase user $new_user setup successfully.";
exit 0;