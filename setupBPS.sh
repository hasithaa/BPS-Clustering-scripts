#!/bin/bash
#
# Copyright (c) 2015.
# This file is licensed under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Author : Hasitha Aravinda (GitHub: https://github.com/hasithaa)
# Date: Dec/14/2015
#
function handleMySQL {
	echo "--------------------------------------"
	echo "  Applying MySQL related config"
	echo "--------------------------------------"
	echo ">> Copy MySQL JDBC Driver"
	cp $db_drive_jar $target/$bps_version/repository/components/lib/ -v >> $log
	if [ $? -ne 0 ]; then
		echo "[Error] Error while coying MySQL drive. Exiting script."
		exit 1;
	fi

	echo ">> Configuring bps-datasources.xml"	
	sed -i.bak "s/jdbc:h2:file:repository\/database\/jpadb;DB_CLOSE_ON_EXIT=FALSE;MVCC=TRUE/jdbc:mysql:\/\/$db_host:$db_port\/$db_bpel/g" $target/$bps_version/repository/conf/datasources/bps-datasources.xml
	sed -i "s/org.h2.Driver/$db_drive/g" $target/$bps_version/repository/conf/datasources/bps-datasources.xml
	sed -i "s/username>wso2carbon/username>$db_user/g" $target/$bps_version/repository/conf/datasources/bps-datasources.xml
	sed -i "s/password>wso2carbon/password>$db_password/g" $target/$bps_version/repository/conf/datasources/bps-datasources.xml

	echo ">> Configuring activiti-datasources.xml"	
	sed -i.bak "s/jdbc:h2:repository\/database\/activiti;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000/jdbc:mysql:\/\/$db_host:$db_port\/$db_bpmn/g" $target/$bps_version/repository/conf/datasources/activiti-datasources.xml
	sed -i "s/org.h2.Driver/$db_drive/g" $target/$bps_version/repository/conf/datasources/activiti-datasources.xml
	sed -i "s/username>wso2carbon/username>$db_user/g" $target/$bps_version/repository/conf/datasources/activiti-datasources.xml
	sed -i "s/password>wso2carbon/password>$db_password/g" $target/$bps_version/repository/conf/datasources/activiti-datasources.xml
	
	echo ">> Configuring $db_um-datasources.xml"
	cp $target/$bps_version/repository/conf/datasources/master-datasources.xml $target/$bps_version/repository/conf/datasources/$db_um-datasources.xml
	sed -i.bak "s/jdbc:h2:repository\/database\/WSO2CARBON_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000/jdbc:mysql:\/\/$db_host:$db_port\/$db_um/g" $target/$bps_version/repository/conf/datasources/$db_um-datasources.xml
	sed -i "s/org.h2.Driver/$db_drive/g" $target/$bps_version/repository/conf/datasources/$db_um-datasources.xml
	sed -i "s/username>wso2carbon/username>$db_user/g" $target/$bps_version/repository/conf/datasources/$db_um-datasources.xml
	sed -i "s/password>wso2carbon/password>$db_password/g" $target/$bps_version/repository/conf/datasources/$db_um-datasources.xml
	sed -i "s/WSO2_CARBON_DB/WSO2_CARBON_UM_DB/g" $target/$bps_version/repository/conf/datasources/$db_um-datasources.xml
	sed -i "s/WSO2CarbonDB/WSO2CarbonUMDB/g" $target/$bps_version/repository/conf/datasources/$db_um-datasources.xml
	echo ">> Configuring user-mgt.xml for datasources change"
	sed -i.bak "s/WSO2CarbonDB/WSO2CarbonUMDB/g" $target/$bps_version/repository/conf/user-mgt.xml

	echo ">> Configuring $db_reg-datasources.xml"
	cp $target/$bps_version/repository/conf/datasources/master-datasources.xml $target/$bps_version/repository/conf/datasources/$db_reg-datasources.xml
	sed -i.bak "s/jdbc:h2:repository\/database\/WSO2CARBON_DB;DB_CLOSE_ON_EXIT=FALSE;LOCK_TIMEOUT=60000/jdbc:mysql:\/\/$db_host:$db_port\/$db_reg/g" $target/$bps_version/repository/conf/datasources/$db_reg-datasources.xml
	sed -i "s/org.h2.Driver/$db_drive/g" $target/$bps_version/repository/conf/datasources/$db_reg-datasources.xml
	sed -i "s/username>wso2carbon/username>$db_user/g" $target/$bps_version/repository/conf/datasources/$db_reg-datasources.xml
	sed -i "s/password>wso2carbon/password>$db_password/g" $target/$bps_version/repository/conf/datasources/$db_reg-datasources.xml
	sed -i "s/WSO2_CARBON_DB/WSO2_CARBON_REG_DB/g" $target/$bps_version/repository/conf/datasources/$db_reg-datasources.xml
	sed -i "s/WSO2CarbonDB/WSO2CarbonREGDB/g" $target/$bps_version/repository/conf/datasources/$db_reg-datasources.xml
	# Adding Registry Mount. 
	if [ $db_reg_add_mount = "true" ]; then
		echo ">> Configuring registry.xml. Adding Registry mount config."
		sed -i.bak "s/<\/registryRoot>/<\/registryRoot>\n<dbConfig name=\"wso2greg\"><dataSource>jdbc\/WSO2CarbonREGDB<\/dataSource><\/dbConfig>\n/g" $target/$bps_version/repository/conf/registry.xml
		sed -i "s/<versionResourcesOnChange>/<remoteInstance url=\"https:\/\/localhost:9443\/registry\">\n<id>instanceid<\/id>\n<dbConfig>wso2greg<\/dbConfig>\n<readOnly>false<\/readOnly><!-- This is a place holder -->\n<enableCache>true<\/enableCache>\n<registryRoot>\/<\/registryRoot>\n<cacheId>$db_user@jdbc:mysql:\/\/$db_host:$db_port\/$db_reg<\/cacheId>\n<\/remoteInstance>\n<mount path=\"\/_system\/config\" overwrite=\"true\">\n<instanceId>instanceid<\/instanceId>\n<targetPath>\/_system\/bpsConfig<\/targetPath>\n<\/mount>\n<mount path=\"\/_system\/governance\" overwrite=\"true\">\n<instanceId>instanceid<\/instanceId>\n<targetPath>\/_system\/governance<\/targetPath>\n<\/mount>\n<versionResourcesOnChange>/g" $target/$bps_version/repository/conf/registry.xml
	fi

	if [ $db_host = "localhost" ]; then
		if [ $db_rebuild_localhost = "true" ]; then
			rm -rf $work/mysql_client.cfg
			echo "[Client]" >> $work/mysql_client.cfg
			echo "user = $db_user" >> $work/mysql_client.cfg
			echo "password = $db_password" >> $work/mysql_client.cfg
			echo "host = $db_host" >> $work/mysql_client.cfg
			echo "port = $db_port" >> $work/mysql_client.cfg
			echo " "
			echo "--------------------------------------"
			echo " Creating databases in MYSQL localhost"
			echo "--------------------------------------"
			echo ">> Creating BPEL db"
			#mysql -u $db_user -p$db_password -e "DROP DATABASE IF EXISTS $db_bpel; CREATE DATABASE $db_bpel; use $db_bpel; $db_bpel_create_sql; commit;" 
			mysql --defaults-extra-file=$work/mysql_client.cfg -e "DROP DATABASE IF EXISTS $db_bpel; CREATE DATABASE $db_bpel; use $db_bpel; $db_bpel_create_sql; commit;" 
			
			if [ $? -ne 0 ]; then
				echo "Database creation problem detected. Exiting script."
				exit 1;
			fi
			echo ">> Creating BPMN db"
			mysql --defaults-extra-file=$work/mysql_client.cfg -e "DROP DATABASE IF EXISTS $db_bpmn; CREATE DATABASE $db_bpmn; use $db_bpmn; $db_bpmn_create_sql; commit;" 
			if [ $? -ne 0 ]; then
				echo "Database creation problem detected. Exiting script."
				exit 1;
			fi
			echo ">> Creating Registry db"
			mysql --defaults-extra-file=$work/mysql_client.cfg -e "DROP DATABASE IF EXISTS $db_reg; CREATE DATABASE $db_reg; use $db_reg; $db_reg_create_sql; commit;" 
			if [ $? -ne 0 ]; then
				echo "Database creation problem detected. Exiting script."
				exit 1;
			fi
			echo ">> Creating UserMgt db"
			mysql --defaults-extra-file=$work/mysql_client.cfg -e "DROP DATABASE IF EXISTS $db_um; CREATE DATABASE $db_um; use $db_um; $db_um_create_sql; commit;" 
			if [ $? -ne 0 ]; then
				echo "Database creation problem detected. Exiting script."
				exit 1;
			fi
			rm -rf $work/mysql_client.cfg
		fi
	else
		echo "[Important] You have selected a MySQL remote host. Please execute following SQL scripts on remote host."
		echo " "
		echo "DROP DATABASE IF EXISTS $db_bpel; CREATE DATABASE $db_bpel; use $db_bpel; $db_bpel_create_sql; commit;"
		echo "DROP DATABASE IF EXISTS $db_bpmn; CREATE DATABASE $db_bpmn; use $db_bpmn; $db_bpmn_create_sql; commit;" 
		echo "DROP DATABASE IF EXISTS $db_reg; CREATE DATABASE $db_reg; use $db_reg; $db_reg_create_sql; commit;"
		echo "DROP DATABASE IF EXISTS $db_um; CREATE DATABASE $db_um; use $db_um; $db_um_create_sql; commit;" 
		echo " "
	fi
	
}

#
# Start of Script.
#
#Current Directory
work=$(pwd)
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
home=$(dirname "$SCRIPT")
log=$(date +'D%Y_%m_%dT%H_%M_%S.log')
echo ">> Reading config from $home/config.cfg ..."
source $home/config.cfg 
echo "Note: this script is compatible from wso2bps-3.5.0 to upper versions."
echo " "
echo "=========================================================="
echo "  Configuring $bps_version"
echo "=========================================================="
echo "Script HOME	$home"
echo "Working directory	$work"
echo "Log file $log"
echo " "
echo ">> Checking for previous BPS installation(s) in target directory ($target)..."	

cd $work
#Cleaning previous unzipped directories.
if [ "`find $target/wso2bps-3* -maxdepth 0 -type d`" ]; then
	echo "[Warning] Found following BPS installation(s) in the target directory." 
	find $target/wso2bps-3* -maxdepth 0 -type d | xargs printf "\t* %s\t\n"
	echo " " 
	read -p "Do you want to delete these directories (yes/no, default yes)? " yes_no_response; yes_no_response=${yes_no_response:-y} 
	if [ $yes_no_response = "y" ] || [  $yes_no_response = "yes"  ]; then
		echo " " 
		echo ">> Cleaning directories..." 
		#Deleting directories.
		find $target/wso2bps-3* -maxdepth 0 -type d | xargs rm -rf 
		echo ">> Cleaning directories is completed..." 	
	elif [ $yes_no_response = "n" ] || [  $yes_no_response = "no"  ]; then
		echo ">> Exiting script, since previous installation exists in working directory...!!!" 
		exit 1;	
	else
		echo "[Error] Invalid input, exiting script ...!!! " 
		exit 1;
	fi 
fi

echo " "
echo "--------------------------------------"
echo " Installing standalone $bps_version"
echo "--------------------------------------"
cd $home
if [ "`find $bps_zip -type f`" ]; then
	echo ">> Unzipping $bps_version zip to target directory $target"
	unzip -q -d $target $bps_zip 
	if [ $? -ne 0 ]; then
		echo "[Error] Unzipping operation failed. Exiting script."
		exit 1;
	fi
	#Validating folder.
	cd $work
	if [ "`find "$target/$bps_version" -maxdepth 0 -type d`" ]; then
		echo "Unzipping $bps_version zip completed."
		
	else
		echo "Unzipped folder validation failed."
		exit 1;
	fi
	
else
	echo "Can't find $bps_version zip script in location $bps_zip. Exiting script."
	exit 1;
fi

echo ">> Copying libraries"
if [ "`find "$config_path_lib" -maxdepth 0 -type d`" ]; then
	cp -r $config_path_lib/*.jar $target/$bps_version/repository/components/lib/ -v  >> $log
	if [ $? -ne 0 ]; then
		echo "	No libs found."
	fi
else
	echo "	No libs found."
fi

echo ">> Copying bundles"
if [ "`find "$config_path_dropings" -maxdepth 0 -type d`" ]; then
	cp -r $config_path_dropings/*.jar $target/$bps_version/repository/components/dropins/ -v  >> $log
	if [ $? -ne 0 ]; then
		echo "	No dropins found."
	fi
else
	echo "	No dropins found."
fi

echo ">> Copying server level libraries"
if [ "`find "$config_path_serverLib" -maxdepth 0 -type d`" ]; then
	cp -r $config_path_serverLib/*.jar $target/$bps_version/lib/ -v  >> $log
	if [ $? -ne 0 ]; then
		echo "	No server level libraries found."
	fi
else
	echo "	No server level libraries found."
fi

echo ">> Copying patches"
if [ "`find "$config_path_patches" -maxdepth 0 -type d`" ]; then
	cp -r $config_path_patches/patch* $target/$bps_version/repository/components/patches/ -v  >> $log
	if [ $? -ne 0 ]; then
		echo "	No patches found."
	fi
else
	echo "	No patches found."
fi

echo ">> Copying Webapps"
if [ "`find "$config_path_webapps" -maxdepth 0 -type d`" ]; then
	cp -r $config_path_webapps/*.war $target/$bps_version/repository/deployment/server/webapps/ -v  >> $log
	if [ $? -ne 0 ]; then
		echo "	No webapps found."
	fi
else
	echo "	No webapps found."
fi

echo ">> Copying custom config"
if [ "`find "$config_path_config" -maxdepth 0 -type d`" ]; then
	#Take Back before replace.
	cp -rbfS.orginal $config_path_config/* $target/$bps_version/repository/conf -v  >> $log
	if [ $? -ne 0 ]; then
		echo "	No custom configuration files found."
	fi
else
	echo "	No custom configuration files found."
fi


if [ $db = "mysql" ] || [  $db = "MYSQL"  ]; then
	handleMySQL
elif [ $db = "h2" ] || [  $db = "H2"  ]; then
	echo ">> Selected database is h2. Neither DB nor clustering related config will apply."
	cluster_enable=false
else
	echo ">> Unsupported database. Please apply DB related config and manually."
fi

# Bulding cluster
if [ $cluster_enable = "true" ]; then
	if [ $cluster_modify_axis2 = "true" ]; then
		echo "--------------------------------------"
		echo "  Applying Clustering related config"
		echo "--------------------------------------"
		echo ">> Configuring clustering in axis2.xml"
		# TODO : Find a better way to replace this. 	
		sed -i.bak_clustering "s/^[ ]*\(enable=\"false\"\)/ enable=\"true\"/g" $target/$bps_version/repository/conf/axis2/axis2.xml
		sed -i "s/membershipScheme\">.*</membershipScheme\">wka</g" $target/$bps_version/repository/conf/axis2/axis2.xml
		sed -i "s/localMemberHost\">.*</localMemberHost\">$cluster_localMemberHost</g" $target/$bps_version/repository/conf/axis2/axis2.xml
		sed -i "s/localMemberPort\">.*</localMemberPort\">$cluster_localMemberPort</g" $target/$bps_version/repository/conf/axis2/axis2.xml
		sed -i "s/<members>/<\!--members>/g" $target/$bps_version/repository/conf/axis2/axis2.xml
		sed -i "s/<\/members>/<\/members-->/g" $target/$bps_version/repository/conf/axis2/axis2.xml
		wkaMemberList="";
		for (( d=0; d<=$cluster_slave_nodes; d++ ))
		do
		wkaMemberList="$wkaMemberList 	<member>\n 		<hostName>$cluster_localMemberHost<\/hostName>\n 		<port>`expr $d \+ $cluster_localMemberPort`<\/port>\n 	<\/member>\n";
		done
		wkaMembers="<members>\n$wkaMemberList<\/members>";
		sed -i "s/<\/members-->/<\/members-->\n$wkaMembers/g" $target/$bps_version/repository/conf/axis2/axis2.xml
		echo ">> Configuring clustering in tasks-config"
		sed -i.bak_clustering "s/<taskServerMode>.*</<taskServerMode>STANDALONE</g" $target/$bps_version/repository/conf/etc/tasks-config.xml
	fi
	if [ $cluster_build_salve = "true" ]; then
		echo "--------------------------------------"
		echo "  Replicating Cluster worker nodes"
		echo "--------------------------------------"
		for (( c=1; c<=$cluster_slave_nodes; c++ ))
		do
		   cp -rf $target/$bps_version $target/$bps_version-worker$c  
		   echo ">> Replicating Cluster worker $c : Offset : `expr $c \* $cluster_slave_offset`"
		   echo "	Configuring carbon.xml for Offset"	
		   sed -i.bak_clustering "s/<Offset>0<\/Offset>/<Offset>`expr $c \* $cluster_slave_offset`<\/Offset>/g" $target/$bps_version-worker$c/repository/conf/carbon.xml
		   echo "	Configuring registry.xml for read-only"	
		   sed -i.bak_clustering "s/false<\/readOnly><!-- This is a place holder -->/true<\/readOnly><!-- This is a place holder -->/g" $target/$bps_version-worker$c/repository/conf/registry.xml
		   echo "	Configuring axis2.xml for port Offset"	
		   sed -i "s/localMemberPort\">.*</localMemberPort\">`expr $c \+ $cluster_localMemberPort`</g" $target/$bps_version-worker$c/repository/conf/axis2/axis2.xml
		done
	fi
fi