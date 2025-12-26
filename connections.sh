#!/bin/bash

# Load initial list
connections=$(cat ~/connect/connections)

if [ $# -gt 0 ]; then
        search="$*"
        for i in $search; do
                # Insert .* between characters to allow for fuzzy matching
                fuzzy_search=$(echo "$i" | sed 's/./&.*/g')
                connections=$(echo "$connections" | grep -E -i "$fuzzy_search")
        done
fi

connections=$(echo "$connections" | sort)

if [ $(echo "$connections" | wc -w) -gt 1 ]; then
        # More than one hit, so user has to choose
        select connection in $connections; 
        do
                echo "$connection"
                break
        done
        user=$(echo "$connection" | awk -F@ '{ print $1 }')
        host=$(echo "$connection" | awk -F@ '{ print $2 }')
        hit="true"
elif [ $(echo "$connections" | wc -w) -eq 1 ]; then
        # One hit only, no need to choose anything
        user=$(echo "$connections" | awk -F@ '{ print $1 }')
        host=$(echo "$connections" | awk -F@ '{ print $2 }')
        echo "$user@$host"
        hit="true"
else
        /usr/bin/host $1 >/dev/null
        if [ $? -eq 0 ]; then
                ~/connect/ssh.exp $1 root
                exit 0
        else
                echo "no hit!"
                exit 1
        fi
fi

ssh -X $user@$host