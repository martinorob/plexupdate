#!/bin/bash

# Script to automagically update Plex Media Server on Synology NAS
#
# Must be run as root.
#
# @author @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/

mkdir /volume1/plextemp/ > /dev/null 2>&1
token=$(cat /volume1/Plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
jq=$(curl -s ${url})
newversion=$(echo $jq | jq -r .nas.Synology.version)
echo New Ver: $newversion
curversion=$(synopkg version "Plex Media Server")
echo Cur Ver: $curversion
if [ "$newversion" != "$curversion" ]
then
echo New Vers Available
/usr/syno/bin/synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'
cpu=$(uname -m)
if [ "$cpu" = "x86_64" ]; then
url=$(echo $jq | jq -r ".nas.Synology.releases[1] | .url")
else
 url=$(echo $jq | jq -r ".nas.Synology.releases[0] | .url")
fi
/bin/wget $url -P /volume1/tmp/plex/
/usr/syno/bin/synopkg install /volume1/tmp/plex/*.spk
sleep 30
/usr/syno/bin/synopkg start "Plex Media Server"
rm -rf /volume1/tmp/plex/*
else
echo No New Ver
fi
exit
