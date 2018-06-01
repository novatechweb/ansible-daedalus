#!/bin/bash
#
# Copyright (C) 2008, 2009, 2010 by Marc Kleine-Budde <mkl@pengutronix.de>
#               2011 by Michael Olbrich <m.olbrich@pengutronix.de>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# ptxd_make_world_extract
#
ptxd_make_world_extract() {
    ptxd_make_world_init || return

    if [ -z "${pkg_url}" -a -z "${pkg_src}" ]; then
	# no <PKG>_URL and no <PKG>_SOURCE -> assume the package has nothing to extract.
	return
    fi

    pkg_extract_dir="${pkg_deprecated_extract_dir:-${pkg_extract_dir}}"

    #
    # strip options which are seperated by ";" form the
    # URL, store in "opts" array
    #
    local orig_ifs="${IFS}"
    IFS=";"
    local -a opts
    opts=( ${pkg_url} )
    IFS="${orig_ifs}"
    unset orig_ifs
    local url="${opts[0]}"
    unset opts[0]

    set -- "${opts[@]}"
    unset opts

    #
    # scan for valid options
    #
    while [ ${#} -ne 0 ]; do
	    local opt="${1}"
	    shift

	    case "${opt}" in
		    svn)
			    echo "SVN project instead of archive file, checking out code.";
			    
			    if [ -e "${pkg_dir}" ]; then
				rm -rf ${pkg_dir};
			    fi;
			    mkdir -p ${pkg_dir};
			    svn checkout ${url} ${pkg_dir}
			    #echo "$(basename "${packet_source}")" >> "${STATEDIR}/packetlist"
			    return
			    ;;
		    git*)
			    local branch=${opt#git=}

			    if [ -e "${pkg_dir}" ]; then
				rm -rf ${pkg_dir};
			    fi;
			    mkdir -p ${pkg_dir};
			    git clone ${url} ${pkg_dir} -b ${branch}
			    return
			    ;;
		    *)
			    ;;
	    esac
    done
    unset opt
    unset url

    case "${pkg_url}" in
	lndir://*)
	    local url="${pkg_url//lndir:\/\//}"
	    if [ -n "${pkg_src}" ]; then
		ptxd_bailout "<PKG>_SOURCE must not be defined when using a lndir:// URL!"
	    fi
	    if [ -d "${url}" ]; then
		echo "local directory using lndir"
		mkdir -p "${pkg_dir}"
		lndir "$(ptxd_abspath "${url}")" "${pkg_dir}"
		return
	    else
		ptxd_bailout "the URL '${pkg_url}' points to non existing directory."
	    fi
	    ;;
	file://*)
	    local url="${pkg_url//file:\/\//}"
	    if [ -n "${pkg_src}" ]; then
		ptxd_bailout "<PKG>_SOURCE must not be defined when using a file:// URL!"
	    fi
	    if [ -d "${url}" ]; then
		echo "local directory instead of tar file, linking build dir"
		ln -sf "$(ptxd_abspath "${url}")" "${pkg_dir}"
		return
	    elif [ -f "${url}" ]; then
		echo
		echo "Using local archive"
		echo
		pkg_src="${url}"
	    else
		ptxd_bailout "the URL '${pkg_url}' points to non existing directory or file."
	    fi
	    ;;
    esac

    mkdir -p "${pkg_extract_dir}" || return

    echo "\
extract: pkg_src=$(ptxd_print_path ${pkg_src})
extract: pkg_extract_dir=$(ptxd_print_path ${pkg_dir})"

    local tmpdir
    tmpdir="$(mktemp -d "${pkg_dir}.XXXXXX")"
    if ! ptxd_make_extract_archive "${pkg_src}" "${tmpdir}"; then
	rm -rf "${tmpdir}"
	ptxd_bailout "failed to extract '${pkg_src}'."
    fi
    local depth=$[${pkg_strip_level:=1}+1]
    if [ -e "${pkg_dir}" ]; then
	tar -C "$(dirname "${tmpdir}")" --remove-files -c "$(basename "${tmpdir}")" | \
	    tar -x --strip-components=${depth} -C "${pkg_dir}"
	check_pipe_status
    else
	mkdir -p "${pkg_dir}" &&
	find "${tmpdir}" -mindepth ${depth} -maxdepth ${depth} -print0 | \
	    xargs -0 mv -t "${pkg_dir}"
	check_pipe_status
    fi
    local ret=$?
    rm -rf "${tmpdir}"
    return ${ret}
}

export -f ptxd_make_world_extract
