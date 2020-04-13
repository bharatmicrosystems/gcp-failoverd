#!/bin/bash
while getopts ":i:e:" opt; do
    case "$opt" in
    i)  internal_vip=$OPTARG
        internal=true
        ;;
    e)  external_vip=$OPTARG
        external=true
        ;;
    esac
done

if $internal; then
    /usr/bin/assign-internal-vip.sh $internal_vip & disown
fi

if $external; then
   /usr/bin/assign-external-vip.sh $external_vip & disown
fi

while true; do
   sleep 1800
done
