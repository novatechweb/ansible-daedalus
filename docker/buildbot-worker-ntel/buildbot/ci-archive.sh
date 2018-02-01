#!/bin/bash
set -x
MACHINE="$1";shift
DESTDIR="$1";shift
TIMESTAMP="$1";shift

# Gather variables from bitbake
bitbake_vars=$(mktemp)
bitbake -e 2>&1 > $bitbake_vars
eval $(grep '^TOPDIR=' $bitbake_vars)
eval $(grep '^TMPDIR=' $bitbake_vars)
eval $(grep '^DEPLOY_DIR=' $bitbake_vars)
eval $(grep '^BUILDHISTORY_DIR=' $bitbake_vars)

# Generate output filename and directory
rootdir="${MACHINE}.${TIMESTAMP}"
filename=${rootdir}.tar.gz
archive="${DESTDIR}/${filename}"

# Gather files to archive into a text file to feed to tar
files_to_archive=$(mktemp)
echo "${DEPLOY_DIR}" >> $files_to_archive
echo "${BUILDHISTORY_DIR}" >> $files_to_archive
find "${TMPDIR}" -type d -name "temp" >> $files_to_archive
echo "$*" >> $files_to_archive

mkdir -p "${DESTDIR}"

# Remove leading and trailing slashes from TOPDIR
TOPDIR=${TOPDIR#/}; TOPDIR=${TOPDIR%/}

# Create the archive, substituting path prefixes of TOPDIR into rootdir
tar --verbose --create --auto-compress \
    --transform "s!^${TOPDIR}!${rootdir}!" \
    --file "${archive}" \
    --files-from="${files_to_archive}"

# Clean up
rm $bitbake_vars
rm $files_to_archive
