#!/bin/bash

# Load initial list
connections=$(cat "$(dirname "$(readlink -f "$0")")/connections.txt")

if [ $# -gt 0 ]; then
        search="$*"
        for i in $search; do
                # Filter the current list of connections by each search term
                connections=$(echo "$connections" | grep -E -i "$i")
        done
fi

connections=$(echo "$connections" | sort)

count=$(echo "$connections" | wc -w)
if [ $count -gt 1 ]; then
        # Exactly two hits, and only differ by _lund/_tving suffix, prefer _lund
        if [ $count -eq 2 ] && [ $(echo "$connections" | awk -F@ '{print $3}' | sed 's/_\(lund\|tving\)$//' | uniq | wc -l) -eq 1 ]; then
                connection=$(echo "$connections" | grep "_lund")
        else
            # More than one hit, so user has to choose
            COLUMNS=1
            select connection in $connections; 
            do
                if [ -z "$connection" ]; then
                    exit 1
                fi
                break
            done
        fi
elif [ $count -eq 1 ]; then
        # One hit only, no need to choose anything
        connection="$connections"
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

# If we found a connection, parse it
if [ -n "$connection" ]; then
        IFS='@' read -r user host name <<< "$connection"
fi

# VPN Routing Logic
# If lundvpn is UP and target name ends in _lund, swap 10.0.1.x for 10.0.2.x
if [[ "$name" == *"_lund" ]] && ip addr show lundvpn >/dev/null 2>&1; then
        host=$(echo "$host" | sed 's/^10\.0\.1\./10.0.2./')
# If tvingvpn is UP and target name ends in _tving, swap 10.0.1.x for 10.0.2.x
elif [[ "$name" == *"_tving" ]] && ip addr show tvingvpn >/dev/null 2>&1; then
        host=$(echo "$host" | sed 's/^10\.0\.1\./10.0.2./')
fi

echo "> ssh $user@$host"
ssh $user@$host