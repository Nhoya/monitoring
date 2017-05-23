#!/bin/bash
#dep: jq, curl, srm
USERID=""
APIKEY=""
TIMEOUT="5"
URL="https://api.telegram.org/bot$APIKEY/sendMessage"
DATE_EXEC="$(date "+%d %b %Y %H:%M")"
TMPFILE=$(tempfile)

if [ -n "$SSH_CLIENT" ]; then
	IP=$(echo $SSH_CLIENT | awk '{print $1}')
	PORT=$(echo $SSH_CLIENT | awk '{print $3}')
	HOSTNAME=$(hostname -f)
	IPADDR=$(hostname -I | awk '{print $1}')
		curl http://ipinfo.io/$IP -s -o $TMPFILE
	CITY=$(cat $TMPFILE | jq '.city' | sed 's/"//g')
	REGION=$(cat $TMPFILE | jq '.region' | sed 's/"//g')
	COUNTRY=$(cat $TMPFILE | jq '.country' | sed 's/"//g')
	ORG=$(cat $TMPFILE | jq '.org' | sed 's/"//g')
	TEXT="$DATE_EXEC: ${USER} logged in to $HOSTNAME ($IPADDR) from $IP - $ORG - $CITY, $REGION, $COUNTRY on port $PORT"
		curl -s --max-time $TIMEOUT -d "chat_id=$USERID&disable_web_page_preview=1&text=$TEXT" $URL > /dev/null
	srm $TMPFILE
	#rm $TMPFILE
fi
