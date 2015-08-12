#!/bin/bash

ROLE_CACHE=/etc/puppet/cache
ENVIRONMENT_PATH=/etc/puppet/environments
ROLE_SERVER=http://nexus
NEXUS_SERVER=http://nexus:8081/nexus/content/repositories/puppet/agileclick

#Collect puppet role from http server
ROLE_N_VERSION=$(curl -s $ROLE_SERVER/$1/role.txt)
ROLE=$(echo $ROLE_N_VERSION | cut -f1,2 -d '_')
VERSION=$(echo $ROLE_N_VERSION | cut -f3 -d '_' | cut -f2 -d 'v')

#For puppet master
ROLE_PATH=$ENVIRONMENT_PATH/$ROLE_N_VERSION
#For stand alone puppet
#ROLE_PATH=/etc/puppet

MODULES_PATH=$ROLE_PATH/modules
MANIFESTS_PATH=$ROLE_PATH/manifests

CACHED_ROLE_FILE=$ROLE_CACHE/$ROLE-$VERSION.tar.gz

#Fetch role from Nexus
if [ -f $CACHED_ROLE_FILE ]; then
	#verify md5
	MD5_URL=$NEXUS_SERVER/$ROLE/$VERSION/$ROLE-$VERSION.tar.gz.md5
	#echo $MD5_URL
	REMOTE_MD5=$(curl -s $MD5_URL)
	LOCAL_MD5=$(md5sum $CACHED_ROLE_FILE | cut -f1 -d ' ')
	if [ ! $REMOTE_MD5 == $LOCAL_MD5 ]; then
		echo "CRAPTASTIC, checksum failed!!"
		exit 1;
	fi
else
	curl -o $CACHED_ROLE_FILE -s $NEXUS_SERVER/$ROLE/$VERSION/$ROLE-$VERSION.tar.gz
fi

#Extract role into environment
#create/refresh environment folder
rm -rf $ROLE_PATH
mkdir $ROLE_PATH $MANIFESTS_PATH $MODULES_PATH 
#create ${environment}/manifests/site.pp
echo "
node default {
	notify { \"Message: What up\":}
}
" > $MANIFESTS_PATH/site.pp

#create ${environment}/modules
#extract role to ${environment}/modules
tar -xf $CACHED_ROLE_FILE -C $MODULES_PATH

echo "---
environment: $ROLE_N_VERSION
classes:
- $ROLE
parameters:
  baserole: $ROLE
"
