#!/bin/bash
#
# Copyright (c) 2018 rootshellz - See LICENSE in this repository (MIT License)
#
# Check a list of hosts (candidates) for UDP DNS resolvers
# Not terribly invasive since each host comes from a public list
# and only receives a few packets (on UDP/53)


# Run: "sudo setcap CAP_NET_RAW+ep /usr/bin/masscan" to avoid the need for sudo on masscan
# Otherwise, fill this in with the path to sudo
SUDO=
PPS_RATE=2048
TIMEOUT=2
TEST_DOMAIN=msn.com
EXPECTED_IP=13.82.28.61
# Some stable A records for testing:
# msn.com -> 13.82.28.61
# linkedin.com -> 108.174.10.10


if [[ "$1" != "" ]]; then
    RESOLVER_CANDIDATES_INPUT_FILE=$1
else
    RESOLVER_CANDIDATES_INPUT_FILE="resolver_candidates.txt"
fi
echo "* Using candidates file: $RESOLVER_CANDIDATES_INPUT_FILE (with $(cat $RESOLVER_CANDIDATES_INPUT_FILE | sort -u | wc -l) candidates)"

if [[ "$2" != "" ]]; then
    OUTPUT_DIRECTORY=$2
    mkdir -p $OUTPUT_DIRECTORY
else
    OUTPUT_DIRECTORY=$(mktemp -d)
fi
echo "* Output directory: $OUTPUT_DIRECTORY"

PORTSCAN_OUTPUT_FILE=$(mktemp -p $OUTPUT_DIRECTORY)
echo "* Port scan output file: $PORTSCAN_OUTPUT_FILE"

OPEN_RESOLVERS_OUTPUT_FILE=open_dns_resolvers-$(date +%F_%T).txt

echo "* Starting port scan"
$SUDO masscan -iL "$RESOLVER_CANDIDATES_INPUT_FILE" -p U:53 -oG "$PORTSCAN_OUTPUT_FILE" --rate "$PPS_RATE"
echo "* Completed port scan"

echo "* Testing resolution on $(cat $PORTSCAN_OUTPUT_FILE | grep open | wc -l) listening resolvers"
for CANDIDATE in $(cat $PORTSCAN_OUTPUT_FILE | grep open | cut -d" " -f2 | sort -uV); do
    echo -n "    Testing resolution on $CANDIDATE: "
    dig -t a +time=${TIMEOUT} $TEST_DOMAIN @$CANDIDATE | grep $EXPECTED_IP 2>&1 1>/dev/null
    if [ "$?" -eq "0" ]; then
        if ! dig +noall +answer -t a +time=${TIMEOUT} myftpbad.${TEST_DOMAIN} @$CANDIDATE | grep IN | grep A 2>&1 1>/dev/null; then
            echo "$CANDIDATE" >> "${OUTPUT_DIRECTORY}/${OPEN_RESOLVERS_OUTPUT_FILE}"
            echo "good!"
        else
            echo "$CANDIDATE" >> "${OUTPUT_DIRECTORY}/hijackers.txt"
            echo "hijacker!"
        fi
    else
        echo "bad!"
    fi
done

echo
echo "--- Results ---"
echo "* $(cat $RESOLVER_CANDIDATES_INPUT_FILE | sort -u | wc -l) candidates"
echo "* $(cat $PORTSCAN_OUTPUT_FILE | grep open | sort -u | wc -l) listening resolvers"
echo "* $(cat ${OUTPUT_DIRECTORY}/${OPEN_RESOLVERS_OUTPUT_FILE} | wc -l) reliable resolvers"
echo "* $(cat ${OUTPUT_DIRECTORY}/hijackers.txt | wc -l) hijackers"
echo "* See ${OUTPUT_DIRECTORY}/${OPEN_RESOLVERS_OUTPUT_FILE} for details"
