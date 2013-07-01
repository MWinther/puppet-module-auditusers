#!/bin/sh
#
# A simple script to log users logged in
# Argument 1, path to a writable diretory
# Argument 2, SITE name, example seln, seki, cnsh, ...
#
if [ $# != 2 ]; then
        echo "Usage: $0 path_to_writeadble_directory site_name"
        exit 1
fi

host=`uname -n`
month=`date +%y%m%d`
base=$1
site=$2
PATH="${PATH}:/usr/bin:/usr/sbin"

if [ -x "/usr/bin/host" ]; then
        ip=`host -a $host | grep -w A 2>/dev/null|awk '{ print $NF }'| head -n1`else
        ip=`nslookup $host | grep Address | tail -1 | awk '{ print $NF }'`
fi

if [ -d "$base" ]; then
        g=$base/$host,NOLOGGEDIN,$ip,$site,$month
        touch $g

        for u in `who | awk '{ print $1 }'`
        do
                /bin/rm -f $g
                f=$base/$host,$u,$ip,$site,$month
                touch $f
        done
else
        echo "Error, writable directory does not exist"
        exit 1
fi

exit 0
