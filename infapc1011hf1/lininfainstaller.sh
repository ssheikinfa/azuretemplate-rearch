#!/bin/sh

#Script arguments
domainHost=${1}
domainName=${2}
domainUser=${3}
domainPassword=${4}
nodeName=${5}
nodePort=${6}

dbType=${7}
dbName=${8}
dbUser=${9}
dbPassword=${10}
dbHost=${11}
dbPort=${12}

sitekeyKeyword=${13}

joinDomain=${14}
osUserName=${15}

storageName=${16}
storageKey=${17}

domainLicenseURL=${18}

echo Starting Informatica setup...
echo Number of parameters $#
#echo $domainHost $domainName $domainUser $domainPassword $nodeName $nodePort $dbType $dbName $dbUser $dbPassword $dbHost $dbPort $sitekeyKeyword $joinDomain $osUserName $storageName $storageKey $domainLicenseURL

#Usage
if [ $# -ne 18 ]
then
	echo lininfainstaller.sh domainHost domainName domainUser domainPassword nodeName nodePort dbType dbName dbUser dbPassword dbHost dbPort sitekeyKeyword joinDomain  osUserName storageName storageKey domainLicenseURL
	exit -1
fi

dbaddress=$dbHost:$dbPort
hostname=`hostname`

informaticaopt=/opt/Informatica
infainstallerloc=$informaticaopt/Archive/server
utilityhome=$informaticaopt/Archive/utilities


infainstallionlocown=/home/Informatica
#mkdir -p $infainstallionlocown/10.1.1

echo Creating symbolic link to Informatica installation
ln -s $infainstallionlocown /home/$osUserName

infainstallionloc=\\/home\\/Informatica\\/10.1.1
defaultkeylocation=$infainstallionloc\\/isp\\/config\\/keys
licensekeylocation=\\/opt\\/Informatica\\/license.key

# Firewall configurations
echo Adding firewall rules for Informatica domain service ports
iptables -A IN_public_allow -p tcp -m tcp --dport 6005:6008 -m conntrack --ctstate NEW -j ACCEPT
iptables -A IN_public_allow -p tcp -m tcp --dport 6014:6114 -m conntrack --ctstate NEW -j ACCEPT

JRE_HOME="$infainstallerloc/source/java/jre"
export JRE_HOME		
PATH="$JRE_HOME/bin":"$PATH"
export PATH

chmod -R 777 $JRE_HOME

cloudsupportenable=1
if [ "$domainLicenseURL" != "nolicense" -a $joinDomain -eq 0 ]
then
	echo Getting Informatica license
	cd $utilityhome
	java -jar iadutility.jar downloadHttpUrlFile -url "$(echo $domainLicenseURL | sed -e s/\ /%20/g)" -localpath "$informaticaopt/license.key"

	if [ -f $informaticaopt/license.key ]
	then
		cloudsupportenable=0
	else
		echo Error downloading license file from URL $domainLicenseURL
	fi
fi


createDomain=1
if [ $joinDomain -eq 1 ]
then
    createDomain=0
	# This is buffer time for master node to start
	sleep 300
else
	echo Creating shared directory on Azure storage
	cd $utilityhome
    java -jar iadutility.jar createAzureFileShare -storageaccesskey $storageKey -storagename "$storageName"
fi

echo Mounting the shared directory
mountdir=/mnt/infaaeshare
mkdir $mountdir
mount -t cifs //$storageName.file.core.windows.net/infaaeshare $mountdir -o vers=3.0,username=$storageName,password=$storageKey,dir_mode=0777,file_mode=0777
echo //$storageName.file.core.windows.net/infaaeshare $mountdir cifs vers=3.0,username=$storageName,password=$storageKey,dir_mode=0777,file_mode=0777 >> /etc/fstab

echo Editing Informatica silent installation file
sed -i s/^LICENSE_KEY_LOC=.*/LICENSE_KEY_LOC=$licensekeylocation/ $infainstallerloc/SilentInput.properties

sed -i s/^USER_INSTALL_DIR=.*/USER_INSTALL_DIR=$infainstallionloc/ $infainstallerloc/SilentInput.properties

sed -i s/^CREATE_DOMAIN=.*/CREATE_DOMAIN=$createDomain/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_DOMAIN=.*/JOIN_DOMAIN=$joinDomain/ $infainstallerloc/SilentInput.properties

sed -i s/^CLOUD_SUPPORT_ENABLE=.*/CLOUD_SUPPORT_ENABLE=$cloudsupportenable/ $infainstallerloc/SilentInput.properties

sed -i s/^ENABLE_USAGE_COLLECTION=.*/ENABLE_USAGE_COLLECTION=1/ $infainstallerloc/SilentInput.properties

sed -i s/^KEY_DEST_LOCATION=.*/KEY_DEST_LOCATION=$defaultkeylocation/ $infainstallerloc/SilentInput.properties

sed -i s/^PASS_PHRASE_PASSWD=.*/PASS_PHRASE_PASSWD=$(echo $sitekeyKeyword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

sed -i s/^SERVES_AS_GATEWAY=.*/SERVES_AS_GATEWAY=1/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_TYPE=.*/DB_TYPE=$dbType/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_UNAME=.*/DB_UNAME=$dbUser/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_PASSWD=.*/DB_PASSWD=$(echo $dbPassword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_SERVICENAME=.*/DB_SERVICENAME=$dbName/ $infainstallerloc/SilentInput.properties

sed -i s/^DB_ADDRESS=.*/DB_ADDRESS=$dbaddress/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_NAME=.*/DOMAIN_NAME=$domainName/ $infainstallerloc/SilentInput.properties

sed -i s/^NODE_NAME=.*/NODE_NAME=$nodeName/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_PORT=.*/DOMAIN_PORT=$nodePort/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_NODE_NAME=.*/JOIN_NODE_NAME=$nodeName/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_HOST_NAME=.*/JOIN_HOST_NAME=$hostname/ $infainstallerloc/SilentInput.properties

sed -i s/^JOIN_DOMAIN_PORT=.*/JOIN_DOMAIN_PORT=$nodePort/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_USER=.*/DOMAIN_USER=$domainUser/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_HOST_NAME=.*/DOMAIN_HOST_NAME=$domainHost/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_PSSWD=.*/DOMAIN_PSSWD=$(echo $domainPassword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

sed -i s/^DOMAIN_CNFRM_PSSWD=.*/DOMAIN_CNFRM_PSSWD=$(echo $domainPassword | sed -e 's/\\/\\\\/g; s/\//\\\//g; s/&/\\\&/g')/ $infainstallerloc/SilentInput.properties

# To speed up installation
mv $infainstallerloc/source $infainstallerloc/source_temp
mkdir $infainstallerloc/source
mv $infainstallerloc/unjar_esd.sh $infainstallerloc/unjar_esd.sh_temp
head -1 $infainstallerloc/unjar_esd.sh_temp > $infainstallerloc/unjar_esd.sh
echo exit_value_unjar_esd=0 >> $infainstallerloc/unjar_esd.sh
chmod 777 $infainstallerloc/unjar_esd.sh

echo Installing Informatica domain
cd $infainstallerloc
echo Y Y | sh silentinstall.sh 


# Revert speed up changes
mv $infainstallerloc/source_temp/* $infainstallerloc/source
rm $infainstallerloc/unjar_esd.sh
mv $infainstallerloc/unjar_esd.sh_temp $infainstallerloc/unjar_esd.sh

if [ -f $informaticaopt/license.key ]
then
	rm $informaticaopt/license.key
fi

echo Changing ownership of directories
chown -R $osUserName $infainstallionlocown
chown -R $osUserName $informaticaopt 
chown -R $osUserName $mountdir
chown -R $osUserName /home/$osUserName

echo Informatica setup Complete.