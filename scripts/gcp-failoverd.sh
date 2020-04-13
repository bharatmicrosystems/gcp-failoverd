#!/bin/bash
while getopts "ie:" opt; do
    case "$opt" in
    i)  internal_vip=$OPTARG
        internal=true
        ;;
    e)  external_vip=$OPTARG
        external=true
        ;;
    esac
done

echo $internal_vip
echo $internal
echo $external_vip
echo $external
