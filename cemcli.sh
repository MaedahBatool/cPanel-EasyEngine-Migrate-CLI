#! /usr/bin/env bash
# Migrate CLI
#
# Migrates cPanel websites to EasyEngine based VPS.
#
# Version: 1.1.0
#
# @param $BACKUP_URL URL to publically downloadable .tar.gz cPanel Backup file.
# @param $BACKUP_FOLDER Backup is downloaded in this folder.
# @param $SITE_URL The old site URL we are migrating.
# @param $db_name Database name for the db that we need to import.
# @param $IS_SUBDOMAIN Is it a subdomain?
# @param $SUBDOMAIN_FOLDER: The sub domain folder.
# @param $IS_STATIC Is this a static site?

# Colors.
#
# colors from tput
# http://stackoverflow.com/a/20983251/950111
# Usage:
# echo "${redb}red text ${gb}green text${r}"
bb=`tput setab 0` #set background black
bf=`tput setaf 0` #set foreground black
gb=`tput setab 2` # set background green
gf=`tput setab 2` # set background green
blb=`tput setab 4` # set background blue
blf=`tput setaf 4` # set foreground blue
rb=`tput setab 1` # set background red
rf=`tput setaf 1` # set foreground red
wb=`tput setab 7` # set background white
wf=`tput setaf 7` # set foreground white
r=`tput sgr0`     # r to defaults

clear
cd ~

# Backup file name that gets downloaded.
BACKUP_FILE=b.tar.gz

# $BACKUP_URL URL to publically downloadable .tar.gz cPanel Backup file.
echo "—"
echo "${gb}${bf} CEM CLI ⚡️  ${r}"
echo "${wb}${bf} Version 1.1.0 ${r}"
echo "${wb}${bf} cPanel to EasyEngine Migration CLI${r}"
echo "—"

echo "${gb}${bf}  ℹ️  Pre CEM CLI Checklist: ${r}"
echo "${wb}${bf}  ␥  1. Have you installed EasyEngine? If not then do it!${r} (INFO: https://easyengine.io/docs/install/)?"
echo "${wb}${bf}  ␥  2. Did you install WPCLI from EasyEngine Stacks?${r} (INFO: https://easyengine.io/docs/commands/stack/)"
echo "${wb}${bf}  ␥  3. Do you have a publically downloadable full backup of your cPanel? ${r}"
echo "${wb}${bf}  ␥  4. Do you have your site's DB Name, USER, PASS, and PREFIX? You can find this inside 'wp-config.php' file. ${r}"
echo "${wb}${bf}  ␥  5. Have you set EasyEngine to ask for DB Name, USER, PASS, and PREFIX? If not then do that by 'sudo nano /etc/ee/ee.conf'${r} (INFO: https://easyengine.io/docs/config/)"
echo "${blb}${bf}  INFO: All the above steps above are required for CEM CLI to work. ${r}"

echo "——————————————————————————————————"
echo "👉  Do you have the INFO required for CEM CLI to run?"
echo "——————————————————————————————————"
read -p "Are you sure? [ y | n ]  " -n 1 -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
	echo
	echo "Quitting..."
	echo "——————————————————————————————————"
	echo "${wb}${rf}  ⚡️  Get the INFO and run CEM CLI again. ${r}"
	echo "——————————————————————————————————"
    exit 1
fi
# if [[ "y" =~ $IS_SUBDOMAIN ]]; then
# 	exit 1
# fi

# Main function.
function cem_cli_init() {
	echo ; echo ; echo # move to a new line
	echo "——————————————————————————————————"
	echo "👉  Enter URL/LINK to a publically downloadable cPanel backup [E.g. http://domain.ext/backup.tar.gz]:"
	echo "——————————————————————————————————"
	echo "NOTES:"
	echo " ␥	1. Backup your site on cPanel via Backup Wizard > Backup > Full Backup > Generate Backup"
	echo " ␥	2. Move the backup to /public_html/ "
	echo " ␥	3. Set the backup file permission 0004"
	echo "——————————————————————————————————"
	read -r BACKUP_URL

	# $SITE_URL The old site we are migrating.
	echo ; echo ; echo # move to a new line
	echo "——————————————————————————————————"
	echo "👉  Enter the SITE URL for the site you are migrating in eaxaclty this format → [E.g. domain.ext or sub.domain.ext]:"
	echo "——————————————————————————————————"
	echo "NOTES:"
	echo " ␥	1. Site name entered here will be created as a site with EasyEngine"
	echo " ␥	2. It's a good practice to be in your server root while running CEM CLI."
	echo "——————————————————————————————————"
	read -r SITE_URL
	BACKUP_FOLDER=$SITE_URL

	# $IS_SUBDOMAIN Is it a subdomain?
	echo ; echo ; echo # move to a new line
	echo "——————————————————————————————————"
	echo "👉  Is this a SUB DOMAIN? Enter [ y | n ]:"
	echo "——————————————————————————————————"
	read -r IS_SUBDOMAIN

	if [[ "y" == $IS_SUBDOMAIN || "Y" == $IS_SUBDOMAIN ]]; then
		# $SUBDOMAIN_FOLDER: The sub domain folder.
		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "👉  Enter the SubDomain FOLDER NAME → [E.g. subdomain ]:"
		echo "——————————————————————————————————"
		echo "NOTES:"
		echo " ␥	1. Each subdomain in cPanel has a folder connected to it inside /public_html/."
		echo " ␥	2. That folder name is what you need to enter here."
		echo "——————————————————————————————————"
		read -r SUBDOMAIN_FOLDER
	fi

	# $IS_STATIC Is this a static site?
	echo ; echo ; echo # move to a new line
	echo "——————————————————————————————————"
	echo "👉  Is this a STATIC SITE? Enter [ y | n ]:"
	echo "——————————————————————————————————"
	echo "NOTES:"
	echo " ␥	1. If this is a static site i.e. an HTML site then type y and press enter."
	echo " ␥	2. If this is a WordPress site then it is not static, type n and press enter."
	echo "——————————————————————————————————"
	read -r IS_STATIC

	if [[ "n" == $IS_STATIC || "N" == $IS_STATIC ]]; then
		# $db_name Database name for the db that we need to import.
		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "👉  Enter the DATABASE name for the db that we need to import → [E.g. site_db]:"
		echo "——————————————————————————————————"
		echo "NOTES:"
		echo " ␥	1. It's important that the database name should be the same as you have on the old host."
		echo " ␥	2. This will be used to search for the database backup inside you downloaded backup."
		echo "——————————————————————————————————"
		read -r db_name
	fi

	# Make the backup dir and cd into it.
	mkdir -p "$BACKUP_FOLDER" && cd "$BACKUP_FOLDER"

	# Save the PWD.
	init_dir=$(pwd)
	echo ; echo ; echo # move to a new line
	echo "——————————————————————————————————"
	echo "⏲  Downloading the backup..."
	echo "——————————————————————————————————"

	if wget "$BACKUP_URL" -O 'b.tar.gz' -q --show-progress  > /dev/null; then
		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "🔥  Backup Download Successful 💯"
		echo "——————————————————————————————————"
		echo "⏲  Now extracting the backup..."
		echo "——————————————————————————————————"

		# Make new dir
		mkdir backup

		# Un tar the backup,
		# -C To extract an archive to a directory different from the current.
		# --strip-components=1 to remove the root(first level) directory inside the zip.
		tar -xvzf $BACKUP_FILE -C backup --strip-components=1

		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "🔥  Backup Extracted to the folder 💯"

		# Delete the backup since you might have lesser space on the server.
		rm -f b.tar.gz

		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "⏲  Let's create the old site with EasyEninge..."
		echo "——————————————————————————————————"

		if [[ "n" == $IS_STATIC || "N" == $IS_STATIC ]]; then
			# Create the site with EE.
			ee site create "$SITE_URL" --wp
		else
			# Create a static site with EE.
			ee site create "$SITE_URL" --html
		fi

		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "⏲  Copying backup files where the belong..."
		echo "——————————————————————————————————"

		# Remove the new site content created by EE.
		rm -rf /var/www/"$SITE_URL"/htdocs/*

		if [[ "y" == $IS_SUBDOMAIN || "Y" == $IS_SUBDOMAIN ]]; then
			# Add the backup content.
			rsync -avz --info=progress2 --progress --stats --human-readable --exclude 'wp-config.php' --exclude 'wp-config-sample.php' "$init_dir"/backup/homedir/public_html/"$SUBDOMAIN_FOLDER"/* /var/www/"$SITE_URL"/htdocs/
		else
			# Add the backup content.
			rsync -avz --info=progress2 --progress --stats --human-readable --exclude 'wp-config.php' --exclude 'wp-config-sample.php' "$init_dir"/backup/homedir/public_html/* /var/www/"$SITE_URL"/htdocs/
		fi

		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "🔥  Backup files were synced with the migrated site."
		echo "——————————————————————————————————"

		# DB Import only if the site is not static.
		if [[ "n" == $IS_STATIC || "N" == $IS_STATIC ]]; then
			echo ; echo ; echo # move to a new line
			echo "——————————————————————————————————"
			echo "⏲  Now importing the SQL database..."
			echo "——————————————————————————————————"

			# Import the DB of old site to new site.
			wp db import "$init_dir"/backup/mysql/"$db_name".sql --path=/var/www/"$SITE_URL"/htdocs/ --allow-root
		fi

		# Delete the backup since you might have lesser space on the server.
		cd ..
		rm -rf $SITE_URL

		# Remove the wp-config.php and sample files.
		rm -f /var/www/$SITE_URL/htdocs/wp-config.php
		rm -f /var/www/$SITE_URL/htdocs/wp-config-sample.php

		# Search Replace not needed for static sites.
		if [[ "n" == $IS_STATIC || "N" == $IS_STATIC ]]; then

			# $IS_SEARCH_REPLACE y if search replace is needed.
			echo ; echo ; echo # move to a new line
			echo "——————————————————————————————————"
			echo "👉  Do you want to search and replace something? [ y/n ]:"
			echo "——————————————————————————————————"
			echo "NOTES:"
			echo " ␥	1. It will run only once."
			echo " ␥	2. This is powered by WPCLI (INFO: http://wp-cli.org/commands/search-replace/)."
			echo "——————————————————————————————————"
			read -r IS_SEARCH_REPLACE

			if [[ "$IS_SEARCH_REPLACE" == "y" ]]; then
				# $SEARCH_QUERY The query of search.
				echo ; echo ; echo # move to a new line
				echo "——————————————————————————————————"
				echo "👉  Enter what you need to SEARCH? [E.g. http://domain.ext ]:"
				echo "——————————————————————————————————"
				echo "NOTES:"
				echo " ␥	1. WP CLI will search for what you enter here.."
				echo " ␥	2. Enter what you want to be searched and replaced"
				echo " ␥	3. E.g. if you want to change http:// to https:// then enter http://domain.ext here."
				echo "——————————————————————————————————"
				read -r SEARCH_QUERY

				# $REPLACE_QUERY The query of replace.
				echo ; echo ; echo # move to a new line
				echo "——————————————————————————————————"
				echo "👉  Enter what you need to REPLACE the search with? [E.g. http://domain.com ]:"
				echo "——————————————————————————————————"
				echo "NOTES:"
				echo " ␥	1. WP CLI will replace what you entered before with what you'll enter here."
				echo " ␥	2. Enter what you want to replace your searched query."
				echo " ␥	3. E.g. if you want to change http:// to https:// then enter https://domain.ext here."
				echo "——————————————————————————————————"
				read -r REPLACE_QUERY

				# Search replace new site.
				wp search-replace "$SEARCH_QUERY" "$REPLACE_QUERY" --path=/var/www/"$SITE_URL"/htdocs/ --allow-root

				echo ; echo ; echo # move to a new line
				echo "——————————————————————————————————"
				echo "🔥  Search Replace is done."
				echo "——————————————————————————————————"
			fi
		fi

		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "-"
		echo "🔥  ✔︎✔︎✔︎ MIGRATION completed for site: $SITE_URL. ✔︎✔︎✔︎"
		echo "-"
		echo "——————————————————————————————————"

	else
		echo ; echo ; echo # move to a new line
		echo "——————————————————————————————————"
		echo "${rb}${wf}  ❌  Backup Download Failed 👎 ${r}"
		echo "——————————————————————————————————"
		echo "ℹ️  TIP: Check if the backup URL you added is a publically downloadable .tar.gz file."
		echo "NOTES:"
		echo " ␥	1. Backup your site on cPanel via Backup Wizard > Backup > Full Backup > Generate Backup"
		echo " ␥	2. Move the backup to /public_html/ "
		echo " ␥	3. Set the backup file permission 0004"
		echo " ␥	4. Start CEM CLI again with command 'cemcli'"
		echo "——————————————————————————————————"

		# Get back to where we were.
		cd ..
		rm -f "$BACKUP_FILE"
		exit 1;
	fi
}

# Run the CLI.
cem_cli_init
