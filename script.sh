#!/bin/bash

#######################################################################
# Author: Henrique Pinheiro                                           #
# Date: 4/19/2014                                                     #
# Title: dns-updater                                                  #
# License: MIT                                                        #
# Description: A tool for connections with dynamic IP                 #
#              adresses that checks for a new IP value and uses       #
#              the DigitalOcean API to update a domain record,        #
#              such as homepc.yourdomain.com.                         #
#######################################################################

# Command to fetch external IP.
# This is suceptable to failure as it relies on
# "ipecho.net", which I do not vouch for.
# Use at your own risk.
IP=$(curl http://ipecho.net/plain 2>/dev/null)

# These are your DigitalOcean credentials
# and domain info. You can get help on finding
# these at the API docs.
API_KEY=[YOUR API KEY]
CLIENT_ID=[YOUR CLIENT ID]
DOMAIN_ID=[YOUR DOMAIN ID]
RECORD_ID=[YOUR RECORD ID]

# This is the complete API request URL,
# that will efectively change your DNS record.
URL="https://api.digitalocean.com/domains/$DOMAIN_ID/records/$RECORD_ID/edit?client_id=$CLIENT_ID&api_key=$API_KEY&record_type=A&data=$IP"

# Interval time between updates.
# Use 's' for seconds, 'm for minutes', 'h' for hours.
TIME=1m

# Setting up constants.
IS_DOWN=0
FIRST_DOWN=0

function main () {
	NEW_IP=$(curl http://ipecho.net/plain 2>/dev/null)
    # If you are connected to the internet...
	if ping -W 200 -c 1 google.com >/dev/null; then
        # If the internet just got back, display a message.
        if [ $IS_DOWN == 1 ]; then
            echo -n "Internet came back at "
            DATE=$(TZ=Brazil/East date +%R | tr -d "\n")
            echo $DATE
            IS_DOWN=0
        fi
        # If your IP is different from the one I had before...
		if [ $IP != $NEW_IP ]; then
            # Make the new one your current, notify the change and use the API to update it.
			IP=$NEW_IP
			echo "Your IP changed. It's now $NEW_IP. Updating it: "
            URL="https://api.digitalocean.com/domains/$DOMAIN_ID/records/$RECORD_ID/edit?client_id=$CLIENT_ID&api_key=$API_KEY&record_type=A&data=$IP"
            curl $URL
        fi
	else
		internet_down
    fi
    dream
    main
}

function dream () {
    echo -n "."
    sleep $TIME
}

function internet_down () {
    # If this is the first time the script finds
    # internet outage, display a message.
    if [ $IS_DOWN != 1 ]; then
        IS_DOWN=1
        echo -n "Internet went down at "
        DATE=$(TZ=Brazil/East date +%R | tr -d "\n")
        echo $DATE
    fi
}

function first_run () {
    echo "dns-updater"
    if ping -W 200 -c 1 google.com >/dev/null; then
        IP=$(curl http://ipecho.net/plain 2>/dev/null)
        echo "Running. Updating IP to $IP."
        URL="https://api.digitalocean.com/domains/$DOMAIN_ID/records/$RECORD_ID/edit?client_id=$CLIENT_ID&api_key=$API_KEY&record_type=A&data=$IP"
        curl $URL 2>/dev/null
        main
    else
        message
        FIRST_DOWN=1
        dream
        first_run
    fi
}

function message () {
    if [ $FIRST_DOWN == 0 ]; then
        echo "Your internet seems to be down."
        echo "The program will run once it gets back up."
    fi
}

first_run