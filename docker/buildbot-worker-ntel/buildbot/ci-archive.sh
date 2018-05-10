#!/bin/bash
set -x
MACHINE="$1";shift
DESTDIR="$1";shift
TIMESTAMP="$1";shift

workdir="build/tmp-glibc-${MACHINE}"
rootdir="${MACHINE}.${TIMESTAMP}"
filename=${rootdir}.tar.gz
archive="${DESTDIR}/${filename}"

files_to_archive=$(mktemp --tmpdir="${workdir}" "files_to_archive.XXXXXXXXXX")

echo "deploy/glibc-${MACHINE}" >> $files_to_archive
echo "buildhistory" >> $files_to_archive
find "${workdir}" -type d -name "temp" >> $files_to_archive
echo "$*" >> $files_to_archive

mkdir -p "${DESTDIR}"

exec tar --verbose --create --auto-compress \
    --transform "s!^!${rootdir}/!" \
    --file "${archive}" \
    --files-from="${files_to_archive}"
