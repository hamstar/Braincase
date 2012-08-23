#!/bin/bash

# Author: Bhavic Patel
# Date:   21 August 2012
# Desc:	  Sets up Dropbox for the first time, also
# 		  This script will:
#			- 
#			- 
#Notes: requires: python-gpgme

#Installs dropbox
setup_dropbox() {
python2.6 dropbox.py start -i
python2.6 dropbox.py autostart

}


