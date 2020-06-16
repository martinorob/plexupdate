#!/bin/bash

# Script to automagically update Plex Media Server on Synology NAS
#
# Must be run as root.
#
# @author @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/

#!/bin/bash
mkdir -p /tmp/plex/ > /dev/null 2>&1
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
CPU=$(uname -m)
url=$(echo "${jq}" | jq -r '.nas.Synology.releases[] | select(.build=="linux-'"${CPU}"'") | .url')
/bin/wget $url -P /tmp/plex/
/usr/syno/bin/synopkg install /tmp/plex/*.spk
sleep 30
/usr/syno/bin/synopkg start "Plex Media Server"
rm -rf /tmp/plex/*
else
echo No New Ver
fi
exit
