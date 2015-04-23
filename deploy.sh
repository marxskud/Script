#!/bin/bash
######################################################################################
###########################     Deploy.sh    #########################################
###########################                  #########################################
######################################################################################
# @author       : Guibert Marc-Antoine
# @PeerReviewer : ???
# @Description  :
#       Deploiement des prerequis et de la configuration d'une application web php5.2.10 
#	mysql 5.1 ubuntu10.04
#
# @Version      : 1.0 07/04/2015
######################################################################################


#Variable
SVN_NAME=
SVN_PASSWORD=
SVN_DEPOT=
TIMESTAMP=$(date +"%Y%m%d%H%M")

MYSQL_HOST=
MYSQL_USER=
MYSQL_PASS=


if [ ${USER} != "root" ];then
	echo "STATUS: Vous devez etre root pour executer ce script"
	exit 1
fi

#Fonction
usage()

{
	echo "Usage     : -e (Deploy environement) -i (install prerequis on the server) -d (import or export dump)"
	echo "Examples:"
	echo "Deployement.sh -d "
	exit 1
}

deploy_application() {
	echo "Nom de votre environement?"
	read CLIENT

	echo "Souhaitez vous deployer le trunk ?"
	read TRUNK

	if [ ${TRUNK} = "yes" ] || [ ${TRUNK} = "Yes" ] || [ ${TRUNK} = "y" ] || [ ${TRUNK} = "Y" ] ;then
		BRANCHE=trunk 
	else
		echo "##############################################  Liste des branches ##############################################"
		svn list --username ${SVN_NAME} --password ${SVN_PASSWORD} --no-auth-cache --non-interactive ${SVN_DEPOT}/branches | cut -d "/" -f1
		echo "################################################################## ##############################################"

		echo "Selectionner dans la liste ci-dessus la branches que vous souhaitez deployer ?"
		read BRANCH_NAME
		BRANCHE=branches/${BRANCH_NAME}
	fi

	if [ ${CLIENT} = "localhost" ] ;then
		echo "Quelle est l'ip de votre serveur ?"
		read IP_SERVER
		echo "<VirtualHost *:80>
		ServerName ${IP_SERVER}
		DocumentRoot /var/www/${CLIENT}
		</VirtualHost>" > /etc/apache2/sites-available/${CLIENT}

		if [ $? -eq 1 ];then
			echo "Error : Set VirtualHost apache2 failed"
			exit 1
		fi
	else

		echo "<VirtualHost *:80>
		ServerName ${CLIENT}.aragon-erh.com
		DocumentRoot /var/www/${CLIENT}
		</VirtualHost>" > /etc/apache2/sites-available/${CLIENT}
		if [ $? -eq 1 ];then
			echo "Error : Set VirtualHost apache2 failed"
			exit 1
		fi
	fi

	a2ensite ${CLIENT}
	if [ $? -eq 1 ];then
		echo "Apache2 Error : A2ensite ${CLIENT} failed"
		exit 1
	fi

	cd /var/www
	svn co -q --username ${SVN_NAME} --password ${SVN_PASSWORD} --no-auth-cache --non-interactive ${SVN_DEPOT}/${BRANCHE}/www ${CLIENT}
	if [ $? -eq 1 ];then
		echo "SVN Error : Checkout source ${BRANCHE} failed"
		exit 1
	fi


	echo "######################## DATABASE SCHEMA LISTE ##############################"
	mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} --password="${MYSQL_PASS}" -e "SHOW DATABASES;"
	echo "#############################################################################" 	
	echo "Quelle est le nom du schema de la DB a utiliser ?"
	read DB_SCHEMA

        sed -i "s/'database' => '${CLIENT}',/'database' => '${DB_SCHEMA}',/g" database.php
        if [ $? -eq 1 ];then
                echo "Error : Sed DB_USER database.php failed"
                exit 1
        fi



	apache2ctl restart
	if [ $? -eq 1 ];then
		echo "APACHE2 Error : apache2 restart failed"
		exit 1
	fi

}

install_server() {

	echo "###################################### STATUS : INSTALLATION DES PACKAGES REQUIS START ######################################"

	echo 'alias l="ls -Flash"' >> ~/.bashrc
	source ~/.bashrc

	apt-get upgrade -y
	if [ $? -eq 1 ];then
		echo "Error : Update failed"
		exit 1
	fi
 
	apt-get update -y
	if [ $? -eq 1 ];then
		echo "Error : Update failed"
		exit 1
	fi

	apt-get install -y python-software-properties
	if [ $? -eq 1 ];then
		echo "Error : Install package python-software-properties failed"
		exit 1
	fi

	add-apt-repository ppa:txwikinger/php5.2
	if [ $? -eq 1 ];then
		echo "Error : Add repository ppa failed"
		exit 1
	fi

	#Ajout de la configuration des packages
	echo "Package: libapache2-mod-php5
Pin: version 5.2.10*
Pin-Priority: 991

Package: libapache2-mod-php5filter
Pin: version 5.2.10*
Pin-Priority: 991

Package: php-pear
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-cgi
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-cli
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-common
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-curl
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-dbg
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-dev
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-gd
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-gmp
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-ldap
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-mhash
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-mysql
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-odbc
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-pgsql
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-pspell
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-recode
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-snmp
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-sqlite
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-sybase
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-tidy
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-xmlrpc
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-xsl
Pin: version 5.2.10*
Pin-Priority: 991

Package: php5-mcrypt
Pin: version 5.2.6*
Pin-Priority: 991

Package: php5-imap
Pin: version 5.2.6*
Pin-Priority: 991" > /etc/apt/preferences.d/php

	if [ $? -eq 1 ];then
		echo "Error : Add preference php failed"
		exit 1
	fi

	apt-get update -y
	if [ $? -eq 1 ];then
		echo "Error : Update failed"
		exit 1
	fi

	apt-get install -y php5 php5-curl php5-gd irb subversion htop iftop php-pear php5-mysql zip openssl build-essential xorg libssl-dev rake
	if [ $? -eq 1 ];then
		echo "Error : Install package failed"
		exit 1
	fi

	echo "Voulez-vous installer mysql et phpmyadmin ?"
	read RESULT

		if [ ${RESULT} = "yes" ] || [ ${RESULT} = "Yes" ] || [ ${RESULT} = "y" ] || [ ${RESULT} = "Y" ] ;then
			apt-get install mysql-server phpmyadmin
			if [ $? -eq 1 ];then
				echo "Error : Install mysql and phpmyadmin failed"
				exit 1
			fi
		fi

	echo "###################################### STATUS : INSTALLATION DES PACKAGES REQUIS OK ######################################"
	echo "###################################### STATUS : CONFIGURATION DE APACHE2 START ######################################"
	a2enmod rewrite
		if [ $? -eq 1 ];then
			echo "Error : Apache rewrite mode failed"
			exit 1
		fi

	sed -i -e '10s/Options Indexes/Options -Indexes/' /etc/apache2/sites-available/default
		if [ $? -eq 1 ];then
			echo "Error : Set options indexes failed"
			exit 1
		fi

	sed -i -e '11s/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default
		if [ $? -eq 1 ];then
			echo "Error : Set allowoverride failed"
			exit 1
		fi

	echo "###################################### STATUS : INSTALLATION DE APACHE2 OK ######################################"
	echo "###################################### STATUS : CONFIGURATION DE APACHE2 php.ini START ######################################"

	sed -i -e 's/session.gc_maxlifetime \= 1440/session.gc_maxlifetime \= 14400/g' /etc/php5/apache2/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Change parameters mawlifetime failed"
			exit 1
		fi

	sed -i -e 's/max_execution_time = 30/max_execution_time = 500/g' /etc/php5/apache2/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set maw_execution_time failed"
			exit 1
		fi

	sed -i -e 's/memory_limit = 16M/memory_limit = 512M/g' /etc/php5/apache2/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set memory_limit failed"
			exit 1
		fi

	sed -i -e 's/post_max_size = 8M/post_max_size = 64M/g' /etc/php5/apache2/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set post_max_size failed"
			exit 1
		fi

	sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 64M/g' /etc/php5/apache2/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set upload_max_filesize failed"
			exit 1
		fi

	sed -i -e 's/expose_php = On/expose_php = Off/g' /etc/php5/apache2/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set expose_php failed"
			exit 1
		fi
	echo "###################################### STATUS : CONFIGURATION DE APACHE2 php.ini OK ######################################"
	echo "###################################### STATUS : CONFIGURATION DE PHP5 php.ini START ######################################"


	sed -i -e 's/session.gc_maxlifetime \= 1440/session.gc_maxlifetime \= 14400/g' /etc/php5/cli/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set session.gc_maxlifetime failed"
			exit 1
		fi

	sed -i -e 's/max_execution_time = 30/max_execution_time = 500/g' /etc/php5/cli/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set max_execution_time failed"
			exit 1
		fi

	sed -i -e 's/memory_limit = 32M/memory_limit = 512M/g' /etc/php5/cli/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set memeory_limit failed"
			exit 1
		fi

	sed -i -e 's/post_max_size = 8M/post_max_size = 64M/g' /etc/php5/cli/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set post_max_size failed"
			exit 1
		fi

	sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 64M/g' /etc/php5/cli/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set upload_max_filesize failed"
			exit 1
		fi

	sed -i -e 's/expose_php = On/expose_php = Off/g' /etc/php5/cli/php.ini
		if [ $? -eq 1 ];then
			echo "Error : Set expose_php in php.ini failed"
			exit 1
		fi
	echo "###################################### STATUS : INSTALLATION DE PHP5 php.ini OK ######################################"
	echo "###################################### STATUS : CONFIGURATION DE apache2.conf START ######################################"

	echo 'ServerSignature Off' >> /etc/apache2/apache2.conf
		if [ $? -eq 1 ];then
			echo "Error : Set ServerSignature in apache2.conf failed"
			exit 1
		fi

	echo 'ServerTokens Prod' >> /etc/apache2/apache2.conf
		if [ $? -eq 1 ];then
			echo "Error : Set ServerTokens in apache2.conf failed"
			exit 1
		fi
	echo "###################################### STATUS : CONFIGURATION DE apache2.conf OK ######################################"
	echo "###################################### STATUS : INSTALLATION DE PEAR START ######################################"

	pear install Mail Mail_Mime Net_SMTP
		if [ $? -eq 1 ];then
			echo "Error : Pear install Mail failed"
			exit 1
		fi

	pear channel-discover components.ez.no
		if [ $? -eq 1 ];then
			echo "Error : Pear set channel failed"
			exit 1
		fi

	pear install -a ezc/eZComponents
		if [ $? -eq 1 ];then
			echo "Error : Pear install eZcomponents failed"
			exit 1
		fi

	echo "###################################### STATUS : INSTALLATION DE PEAR OK ######################################"

	echo "###################################### STATUS : INSTALLATION DE wkhtmltopdf START ######################################"
	cd ~/
	wget -q http://wkhtmltopdf.googlecode.com/files/wkhtmltopdf-0.9.9-static-amd64.tar.bz2
		if [ $? -eq 1 ];then
			echo "Error : Wget wkhtmltopdf failed"
			exit 1
		fi

	tar xjf wkhtmltopdf-0.9.9-static-amd64.tar.bz2
		if [ $? -eq 1 ];then
			echo "Error : Unzip wkhtmltopdf failed"
			exit 1
		fi

	rm wkhtmltopdf-0.9.9-static-amd64.tar.bz2
		if [ $? -eq 1 ];then
			echo "Error : rm wkhtmltopdf failed"
			exit 1
		fi

	mv wkhtmltopdf-amd64 /usr/local/bin/wkhtmltopdf
		if [ $? -eq 1 ];then
			echo "Error : mv wkhtmltopdf failed"
			exit 1
		fi

	chmod +x /usr/local/bin/wkhtmltopdf
		if [ $? -eq 1 ];then
			echo "Error : Set right wkhtmltopdf failed"
			exit 1
		fi

	echo "###################################### STATUS : INSTALLATION DE wkhtmltopdf OK ######################################"
	echo "###################################### STATUS : INSTALLATION DES PREREQUIS SERVER TERMINE AVEC SUCCES ######################################"

}

dump() {
echo "Creer un nouvelle DB ou exporter / importer un DUMP,veuillez selectionner votre choix"
SELECTION="Create Import Export quit"
select options in $SELECTION; do
	if [ "$options" = "Import" ]; then
		echo "################################# $options DUMP ##############################"
		echo "Quelle est le nom du dump a importer?"
		read DUMP_NAME
		echo "################################# Liste DB ###################################"
		mysql -u ${MYSQL_USER} --password="${MYSQL_PASS}" -e "show databases\G;"
		echo "##############################################################################"
		echo "Quelle est le nom de la DB (ci-dessus DB existante ?"
		read DB_NAME
		echo "################################ $options $DUMP_NAME sur $DB_NAME ############"
		mysql -u ${MYSQL_USER} -p ${DB_NAME} --password="${MYSQL_PASS}" < ${DUMP_NAME}
		if [ $? -eq 1 ];then
			echo "ERROR: Import du dump failed"
			exit 1
		fi
		mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p ${DB_NAME} --password="${MYSQL_PASS}" -e "SHOW TABLES;"
		echo "################# $options $DUMP_NAME sur $DB_NAME OK ########################"
		exit 0

	elif [ "$options" = "Create" ]; then
                echo "################################# $options DUMP ##############################"
	 	echo "Quelle est le nom de la DB ? "
		read DB_NAME
		mysql -u ${MYSQL_USER} --password="${MYSQL_PASS}" -e "CREATE DATABASE ${DB_NAME};" 
		if [ $? -eq 1 ];then
                        echo" ERROR: Create database failed"
                        exit 1
                fi
		mysql -u ${MYSQL_USER} --password="${MYSQL_PASS}"-e "SHOW DATABASES;"
	    	exit 0
	elif [ "$options" = "Export" ]; then
	    echo "##################################### $options DUMP ##############################"
                echo "################################# Liste DB ###################################"
                mysql -u ${MYSQL_USER} --password="${MYSQL_PASS}" -e "show databases;"
                echo "##############################################################################"
		echo "Quelle DB voulez vous exporter (export dans /tmp) ?"
		read DB_NAME
		mysqldump -u ${MYSQL_USER} -p ${DB_NAME} --password="${MYSQL_PASS}" > /tmp/${DB_NAME}_${TIMESTAMP}.sql
		if [ $? -eq 1 ];then
                        echo" ERROR: Export du dump failed"
                        exit 1
                fi

		exit 0
	elif [ "$options" = "quit" ]; then
	    	exit 0
	else
	    clear;
	    echo "Cette options n'existe pas, Selectionné une options"

	fi
done
}

#Usage
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        usage
fi

#Main
while getopts "eid" option
do
        case $option in

           e)
                        deploy_application
                ;;
           i)
			install_server	
                ;;
           d)
			dump
                ;;

           \?)
                        echo "$OPTARG : option not valid"
                        exit 1
                ;;
        esac
done
