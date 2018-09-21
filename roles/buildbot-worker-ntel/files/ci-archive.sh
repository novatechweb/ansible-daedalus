#!/bin/bash
set -x
PREFIX="$1";shift
ARCHIVE="$1";shift

mkdir -p "$(dirname $ARCHIVE)"

# Gather variables from bitbake
bitbake_vars="$(mktemp)"
bitbake -e orion-headless-image 2>&1 > $bitbake_vars
eval $(grep '^TOPDIR=' $bitbake_vars)
eval $(grep '^TMPDIR=' $bitbake_vars)
eval $(grep '^DEPLOY_DIR=' $bitbake_vars)
eval $(grep '^BUILDHISTORY_DIR=' $bitbake_vars)

# Gather files to archive into a text file to feed to tar
files_to_archive="$(mktemp)"
echo "${DEPLOY_DIR}" >> $files_to_archive
echo "${BUILDHISTORY_DIR}" >> $files_to_archive
find "${TMPDIR}" -type d -name "temp" >> $files_to_archive
echo "$*" >> $files_to_archive

# Remove leading and trailing slashes from TOPDIR
TOPDIR=${TOPDIR#/}; TOPDIR=${TOPDIR%/}

# Create the archive, substituting path prefixes of TOPDIR into rootdir
tar --verbose --create --auto-compress \
    --transform "s!^${TOPDIR}!${PREFIX}!" \
    --file "${ARCHIVE}" \
    --files-from="${files_to_archive}"

# Clean up
rm $files_to_archive
rm $bitbake_vars
