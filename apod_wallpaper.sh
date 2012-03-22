#!/bin/sh
#
# a simple script to change the gnome desktop background
#  to the current NASA Astronomy Picture of the Day
#
#


##########################################
# code to set proper crontab environment
##########################################

nautilus_pid=`pgrep -u $LOGNAME -n nautilus`

if [ -z "$nautilus_pid" ]; then
  exit 0
fi

# Grab the DBUS_SESSION_BUS_ADDRESS variable from nautilus's environment
eval `tr '\0' '\n' < /proc/$nautilus_pid/environ | 
	grep '^DBUS_SESSION_BUS_ADDRESS='`

# Check that we actually found it
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  echo "Failed to find bus address" >&2
  exit 1
fi

# export it so that child processes will inherit it
export DBUS_SESSION_BUS_ADDRESS




BASE_URL="http://apod.nasa.gov/apod/"
IMAGE_PATH="image/`date +%y%m`/"
INDEX_PAGE="astropix.html"



if test ! -d "$HOME/apod/" ; then
	mkdir $HOME/apod/
	if test $? -ne 0 ; then
		echo "Couldn't create directory $HOME/apod/" >&2
		exit 1
	fi
fi

cd $HOME/apod/
rm $INDEX_PAGE
wget $BASE_URL$INDEX_PAGE

if test $? -ne 0 ; then
	echo "Error retrieving index page" >&2
	exit 1
fi



FILENAME=`grep "href=\"$IMAGE_PATH" astropix.html | 
	sed "s&.*$IMAGE_PATH\(.*\.jpg\).*&\1&"`

if test $? -ne 0 ; then
	echo "Error parsing image URL" >&2
	exit 1
fi

if test -e $FILENAME ; then
	MODTIME=`stat -c%Y $FILENAME`
	CURTIME=`date +%s`
	AGE=`expr $CURTIME - $MODTIME`
	if test $AGE -lt 86400; then
		rm $INDEX_PAGE
		exit
	else
		rm $FILENAME
	fi
fi

wget "$BASE_URL$IMAGE_PATH$FILENAME"

if test $? -ne 0 ; then
	echo "Error retrieving image" >&2
	exit 1
fi

#gconftool -t string -s /desktop/gnome/background/picture_filename \
#	$HOME/apod/$FILENAME

gsettings set org.gnome.desktop.background picture-uri \
	file://"$HOME/apod/$FILENAME"


if test $? -ne 0 ; then
	echo "Error setting wallpaper" >&2
	exit 1
fi

gsettings set org.gnome.desktop.background picture-options \
	stretched

# avoids caching of partially loaded wallpaper
touch $FILENAME

rm $INDEX_PAGE
