#!/bin/bash

################################################################################
#                          ADS-BENCHMARK by Dacteev                            #
################################################################################

hash phantomjs 2>/dev/null || { echo >&2 "I require phantomjs but it's not installed.  Aborting."; exit 1; }

usage() {
    echo "Usage: $0 \"http://example.com\" <owner> <sleepsecs>"
    echo "    $0 \"http://example.com\" \"first name\""
}

## Initialization
country="nocountry"
city="nocity"
isp="noisp"
owner=$(whoami)
sleeping=60
output_dir=data

if [ -z "$1" ]
then
    usage
    exit 1
fi

if [ -n "$2" ]
then
    owner=$(echo -n $2 | tr ' ' '_')
fi

if [ -n "$3" ]
then
    sleeping=$3
fi

re='^[0-9]+$'
if ! [[ $sleeping =~ $re ]]
then
    usage
    echo "error: The sleeping delay is not a number" >&2
    exit 1
fi

domain=$(echo $1 | awk -F/ '{print $3}')

if [ -z "$domain" ]
then
    usage
    echo "error: The given URL is invalid"
    exit 1
fi

## Routines
benchmark_info() {
    tmp_file=/tmp/ad_benchmarks.wget
    wget_cmd=$(which wget)
    if [ -z "$wget_cmd" ]
    then
        echo "warning: No tool available to get your information"
        output_dir="${output_dir}/${country}/${city}/${isp}"
    else
        touch $tmp_file
        if [ ! -w $tmp_file ]
        then
            echo "warning: Could not write a temporary file in /tmp"
            output_dir="${output_dir}/${country}/${city}/${isp}"
        fi

        $wget_cmd -q -O $tmp_file --user-agent="The Dacteev AdServer Benchmark Agent"  http://www.whatismyip.com/

        # Getting the two letters country code
        country=$(grep "the-country" $tmp_file \
		| sed -e 's/.*the-country">\([a-zA-Z][a-zA-Z]\).*/\1/g' \
		| tr '[:upper:]' '[:lower:]')

        # Getting the city name
        city=$(grep "the-city" $tmp_file \
		| sed -e 's/.*the-city">\([a-zA-Z -]*\).*/\1/g' \
		| tr '[:upper:]' '[:lower:]' \
		| tr " -" '_')

        # Getting the isp name
        isp=$(grep "the-isp" $tmp_file \
		| sed -e 's/.*the-isp">\([a-zA-Z\/ -]*\).*/\1/g' \
		| tr '[:upper:]' '[:lower:]' \
		| tr "/ -" '_')

        output_dir="${output_dir}/${country}/${city}/${isp}"

        rm $tmp_file
    fi
}

## Benchmark preparation
benchmark_info
echo "info: --- Output directory set to:  $output_dir"
echo "info: --- Files nomenclature:       $output_dir/${owner}-${domain}-{timestamp}.har"

if [[ ! -e "$output_dir" ]]
then
    mkdir -p $output_dir
fi

## Benchmark loop 
while true
do
    timestamp=$(date +%s)

    echo -n "Creating ${owner}-${domain}-${timestamp}.har"
    phantomjs netsniff.js $1 > "data/${country}/${city}/${isp}/${owner}-${domain}-${timestamp}.har" 2> >(grep -v CoreText 1>&2)
    echo -e "\t\t[  ok  ]"

    sleep "${sleeping}"
done
