#!/usr/bin/env bash

for i in $(seq 0 20); do
    ./random &> /dev/null
    RET=$?
    if [[ 0 -eq ${RET} ]]; then
	OK=${OK}.
    else
	SEGF=${SEGF}#
    fi
done

echo ${SEGF}${OK}

