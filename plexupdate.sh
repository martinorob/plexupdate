#!/bin/bash
# Script to Auto Update Plex on Synology NAS
#
# Must be run as root.
#
# @author Martino https://forums.plex.tv/u/Martino
# @see https://forums.plex.tv/t/script-to-auto-update-plex-on-synology-nas-rev4/479748

mkdir -p /tmp/plex/
DSM=$(cat /etc/VERSION | grep -oP 'majorversion="\K[^"]+')
echo "Detected DSM version $DSM"
if [ "$DSM" = "7" ] ; then
    TOKEN=$(cat /volume1/@apphome/PlexMediaServer/Plex\ Media\ Server/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
  else
    TOKEN=$(cat /volume1/Plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
  fi
URL=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=${TOKEN}")
JSON=$(curl -s ${URL})
if [ "$DSM" = "7" ] ; then
    NEW_VERSION=$(echo $JSON | jq -r '.nas."Synology (DSM 7)".version')
  else
    NEW_VERSION=$(echo $JSON | jq -r '.nas.Synology.version')
  fi
echo "New version: ${NEW_VERSION}"
CURRENT_VERSION=$(synopkg version "PlexMediaServer")
echo "Current version: ${CURRENT_VERSION}"
if [ "${NEW_VERSION}" != "${CURRENT_VERSION}" ] ; then
  echo "New version available!"
  /usr/syno/bin/synonotify PKGHasUpgrade '{"Plex will be automatically updated to ${NEW_VERSION}"}'
  CPU=$(uname -m)
  if [ "$DSM" = "7" ] ; then
    if [ "$CPU" = "x86_64" ] ; then
    URL=$(echo $JSON | jq -r '.nas."Synology (DSM 7)".releases[1] | .url')
    else
    URL=$(echo $JSON | jq -r ".nas."Synology (DSM 7)".releases[0] | .url")
    fi
  else
    if [ "$CPU" = "x86_64" ] ; then
    URL=$(echo $JSON | jq -r ".nas.Synology.releases[1] | .url")
    else
    URL=$(echo $JSON | jq -r ".nas.Synology.releases[0] | .url")
    fi
  fi
  /bin/wget $URL -P /tmp/plex
  /usr/syno/bin/synopkg install /tmp/plex/*.spk
  sleep 30
  /usr/syno/bin/synopkg start "PlexMediaServer"
  rm -rf /tmp/plex
else
  echo "Plex is up to date."
fi
exit 0
