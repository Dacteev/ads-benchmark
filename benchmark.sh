#!/bin/bash

hash phantomjs 2>/dev/null || { echo >&2 "I require phantomjs but it's not installed.  Aborting."; exit 1; }

usage() {
    echo "Usage: $0 \"http://example.com\" <owner> <sleepsecs>"
    echo "    $0 \"http://example.com\" \"first name\""
}

country=""
city=""
isp=""
owner=$(whoami)
sleeping=60

if [ -z "$1" ]
then
    usage
    exit 1
fi

if [ -n "$2" ]
then
    owner=$2
fi

if [ -n "$3" ]
then
    sleeping=$3
fi

re='^[0-9]+$'
if ! [[ $sleeping =~ $re ]]
then
    usage
    echo "error: Not a number" >&2
    exit 1
fi

domain=$(echo $1 | awk -F/ '{print $3}')

if [ -z "$domain" ]
then
    usage
    echo "Url is invalid"
    exit 1
fi

if [[ ! -e "data/${country}/${city}/${isp}/" ]]
then
    mkdir -p "data/${country}/${city}/${isp}/"
fi

while true
do
    timestamp=$(date +%s)

    echo -n "Create ${owner}-${domain}-${timestamp}.har"
    phantomjs netsniff.js $1 > "data/${country}/${city}/${isp}/${owner}-${domain}-${timestamp}.har" 2> >(grep -v CoreText 1>&2)
    echo -e "\t\t[  ok  ]"

    sleep "${sleeping}"
done
