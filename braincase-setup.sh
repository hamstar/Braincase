#Braincase Install Script
#V: 2-7-2012
#By Bhavic Patel

#Licence ??


#### Variables ####
dbuser=braincase
dbwikiname=braincasewiki


########### Intial Checks #############
##Check we are in CentOS
	if [ -f /etc/debian_version ]; then
		OS=Debian  # XXX or Ubuntu??
		VER=$(cat /etc/debian_version)
		echo "Debian or Ubuntu isn't supported!...... Exiting "
		exit
	fi
	#elif [ -f /etc/redhat-release ]; then



########### Installing Dependences #########
	##Install Dependeces for Mediawiki
	###TODO: Check whether server might have httpd already installed. If so, will have to ask user for public_html location
	###TODO: CENTOS 5.6 NEEDS PACKAGE: php53 (NOT 'php' which installs 5.1)
	yum -qy upgrade #Upgrade System
	yum install -qy wget tar #Just incase. Some minimal systems don't seem to include these
	yum install -qy httpd mysql-server php php-mysql #Install required dependences. Use -qy for quiet and yes to all questions.
	#Check if exit status 0 which means ALL GOOD
	if [ ! $? -eq 0 ]; then
		echo "Error installing dependences"
		exit
	fi
	
	##Extra Things
	#Sendmail for sending mail
	#php-gd for image thumbnailing
	#TeX for inline display for mathematical forumlae
	yum install -qy sendmail php5-gd tetex



########### Configure MySQL ##########
cd /usr ; /usr/bin/mysqld_safe & #start mysql
password=`randpass 10 0` #generates a random pass
/usr/bin/mysqladmin -u root password $password
/usr/bin/mysqladmin -u root -p$password create $dbwikiname
/usr/bin/mysql -uroot -p$password -A -e "grant index, create, select, insert, update, delete, alter, lock tables on $dbwikiname.* to '$dbuser'@'localhost' identified by '$password';"

########### Installing Media Wiki
	#Download Mediawiki latest as of this script
	mkdir ~/braincase
	cd ~/braincase && wget http://download.wikimedia.org/mediawiki/1.19/mediawiki-1.19.1.tar.gz && tar xvzf mediawiki-*.tar.gz
	cd mediawiki-*
	##TODO: We need to get the following two from the user (Start of script?)
	##<name>: The name of the wiki
    ##<admin>: The username of the wiki administrator (WikiSysop)

	php maintenance/install.php [--conf|--confpath|--dbname|--dbpass|--dbpassfile|--dbpath|--dbport|--dbprefix|--dbserver|--dbtype|--dbuser|--env-checks|--globals|--help|--installdbpass|--installdbuser|--lang|--memory-limit|--pass|--quiet|--scriptpath|--server|--wiki] <name> <admin>
	
	
########## Misc Functions ###########
##Random Password Generator. Source: http://legroom.net/2010/05/06/bash-random-password-generator
# Generate a random password
#  $1 = number of characters; defaults to 32
#  $2 = include special characters; 1 = yes, 0 = no; defaults to 1
function randpass() {
  [ "$2" == "0" ] && CHAR="[:alnum:]" || CHAR="[:graph:]"
    cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32}
    echo
}
