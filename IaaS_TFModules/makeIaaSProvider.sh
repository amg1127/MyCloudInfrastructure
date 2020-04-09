#!/bin/bash
me="${0}"
symlink='active'

if [ "x${1}" == 'x' ]; then
    echo "Usage: ${me} <IaaSProvider> ..."
    exit 1
fi

if [ -h "${me}" ]; then
    me="`readlink -f \"${me}\"`"
fi
cd "`dirname \"${me}\"`" || exit 1

if ! [ -h "${symlink}" -a -d "${symlink}/././" ]; then
    echo "Symbolic link '${symlink}' does not exist or is invalid!"
    exit 1
fi

while [ "x${1}" != 'x' ]; do
    IaaSProvider="${1}"
    find "${symlink}/" -mindepth 1 -maxdepth 1 -type d -exec basename '{}' ';' | while read module; do
        mkdir -pv "${IaaSProvider}/${module}"
        for file in variables outputs; do
            ln -sfv "../../${module}.${file}.tf" "${IaaSProvider}/${module}/${file}.tf"
        done
    done
    shift
done
