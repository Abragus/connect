#!/bin/bash
tmp=~/connect/connections.$$
cp ~/connect/connections $tmp
if [ $# -gt 0 ]; then
        search="$*"
        for i in `echo $search`; do
                connections=`grep -i $i $tmp >  $tmp.swap`
                mv $tmp.swap $tmp
        done
fi

connections=`sort $tmp`

if [ `echo $connections | wc -w` -gt 1 ]; then
        # More than one hit, so user has to choose
        select connection in $connections; 
        do
                echo "$connection"
                break
        done
        user=`echo $connection | awk -F@ '{ print $1 }'`
        host=`echo $connection | awk -F@ '{ print $2 }'`
        hit="true"
elif [ `echo $connections | wc -w` -eq 1 ]; then
        # echo " One hit only, no need to choose anything"
        user=`echo $connections | awk -F@ '{ print $1 }'`
        host=`echo $connections | awk -F@ '{ print $2 }'`
        echo "$user@$host"
        hit="true"
else
        /usr/bin/host $1 >/dev/null
        if [ $? -eq 0 ]; then
                # echo " Assume TE host"
                rm $tmp
                ~/connect/ssh.exp $1 root
                # ssh root@
                exit 0
        else
                echo "no hit!"
                rm $tmp
                exit 1
        fi
fi

rm $tmp
ssh -X $user@$host
