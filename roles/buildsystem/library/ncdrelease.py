#!/usr/bin/python

__author__ = 'Mark'

# 3rd party python modules to import
from ansible.module_utils.basic import *

# Standard python modules to import
from datetime import datetime
import logging
import os
import shutil
from string import lstrip as left_strip
from string import replace as str_replace
from string import rstrip as right_strip
import tarfile
import time
import zipfile

# 3rd party python modules to import
import pysvn

# NovaTech python modules to import
# None


DOCUMENTATION = '''
---
module: ncdrelease
version_added: "post 1.9.1"
author: Mark King
short_description: Scan and process SVN repo.
description:
  - Will release any protocols that are in the beta release file. Then it will scans the given NCD Release url and
    generate a file of the current status of the repo.  While checking the current status of the repo if a destination
    directory is given the newest release (by number) is pulled down.

options:
  svn_username:
  description:
      - The username to access the NCD repository with.
  required: true

  svn_password:
  description:
      - The password to access the NCD repository with.
  required: true

  ncd_release_repo:
  description:
      - The NCD repository url.
  required: true

  new_releases_file:
  description:
      - A files that contains a list of items to release.  The format of a line is '[protocol] [type]' where [type]
        would be like default OCX or something similar.
  required: false

  local_checkout_dir:
    description:
      - The directory where the newest releases in the NCD repository will be stored at locally.
    required: false

  releases_status_logfile:
    description:
      - The filename for printing out information about the NCD release repo.
    default: ncd_repo_status

  releases_status_logfile_level:
    description:
      - The filename for printing out information about the NCD release repo.
    default: DEBUG
'''

EXAMPLES = '''
# Checks the release vs current status of the NCD Release repo.
- ncdrelease:
    svn_username: username
    svn_password: username_password
    ncd_release_repo: http://some_repo/

# Release the given protocols and type in the 'beta.txt' file then checks the release vs current status of the
#   NCD Release repo.
- ncdrelease:
    svn_username: username
    svn_password: username_password
    ncd_release_repo: http://some_repo/
    new_releases_file: beta.txt

# Checks the release vs current status of the NCD Release repo, grabs the newest release in the ncd release repo, and
#   places them in the give local directory.
- ncdrelease:
    svn_username: username
    svn_password: username_password
    ncd_release_repo: http://some_repo/
    local_checkout_dir: /home/user/local_workspace/NCD

# Checks the release vs current status of the NCD Release repo, grabs the newest release in the ncd release repo, places
#   them in the give local directory, and then makes an archive of the directory.
- ncdrelease:
    svn_username: username
    svn_password: username_password
    ncd_release_repo: http://some_repo/
    local_checkout_dir: /home/user/local_workspace/NCD

# Release the given protocols and type in the 'beta.txt' file, checks the release vs current status of the NCD Release
#   repo, grabs the newest release in the ncd release repo, places them in the give local directory, and then makes an
#   archive of the directory.
- ncdrelease:
    svn_username: username
    svn_password: username_password
    ncd_release_repo: http://some_repo/
    new_releases_file: beta.txt
    local_checkout_dir: /home/user/local_workspace/NCD
'''


def setup_logging(filename, start_time, level=logging.DEBUG):
	logging_format = '%(levelname)8s : %(message)s'
	log_filename = "{0:}_{1:}.log".format(filename, start_time)
	logging.basicConfig(filename=log_filename, level=level, format=logging_format, filemode='w')


def tag_new_releases(client, repo_url, release_filename):
	betas_to_release = []
	with open(release_filename, 'r') as release_file:
		for line in release_file:
			betas_to_release.append(line.strip().split())

	for release_protocol, release_type in betas_to_release:
		# Get latest rev number
		releases_url = "{0:}/{1:}/{2:}/releases".format(repo_url, release_protocol, release_type)

		cur_release_info = get_newest_release(client, releases_url)
		if cur_release_info == {}:
			new_release_num = "1.00"
		else:
			major, minor = cur_release_info['name'].split('.')
			new_release_num = "{0:}.{1:02}".format(major, (int(minor) + 1))

		# Generate the needed URLs
		current_url = "{0:}/{1:}/{2:}/current".format(repo_url, release_protocol, release_type)
		new_release_url = "{0:}/{1:}/{2:}/releases/{3:}".format(repo_url, release_protocol, release_type, new_release_num)

		# Create new message
		message = "Tagging {0:} release of {1:} {2:}.".format(new_release_num, release_protocol, release_type)
		logging.info(message)

		def log_message():
			return True, message

		# Issue svn copy
		client.callback_get_log_message = log_message
		client.copy(current_url, new_release_url)


def get_newest_release(client, url):
	releases = simple_list(client, url)
	releases_names = sorted(releases, reverse=True)

	latest_release_by_date = {}
	for release_name in releases_names:
		release_info = releases[release_name]
		if latest_release_by_date == {}:
			latest_release_by_date = release_info
		elif latest_release_by_date['commit_time_raw'] < release_info['commit_time_raw']:
			latest_release_by_date = release_info

	latest_release_by_version = {}
	if not(releases == {}):
		latest_release_by_version = releases[releases_names[0]]

	if latest_release_by_version != latest_release_by_date:
		logging.warning("Newest commit release by date doesn't have the highest release number.")
		logging.warning("Newest commit:---- release: {name:}, commit time: {commit_time:}, url: {url}".format(
			**latest_release_by_date))
		logging.warning("Highest release #: release: {name:}, commit time: {commit_time:}, url: {url}".format(
			**latest_release_by_version))

	return latest_release_by_version


def simple_list(client, url):
	return_value = dict()
	options = client.list(url)
	for option in options:
		path = option[0]['path']
		commit_time = time.ctime(option[0]['time'])
		is_directory = option[0]['kind'] == pysvn.node_kind.dir
		dir_name = path.split("/")[-1]
		if path != url:
			return_value[dir_name] = {
				'name':            dir_name,
				'url':             path,
				'commit_time':     commit_time,
				'commit_time_raw': option[0]['time'],
				'is_directory':    is_directory,
			}
	return return_value


def scan_protocols(client, url, local_dir):
	protocols = simple_list(client, url=unicode(url))

	for protocol_name in sorted(protocols.keys()):
		protocol_info = protocols[protocol_name]

		if protocol_info['is_directory']:
			data_types = simple_list(client, protocol_info['url'])

			for data_name in sorted(data_types.keys()):
				data_info = data_types[data_name]

				if data_info['is_directory']:
					states = get_states(client, data_info['url'])
					if 'releases' in states:
						checkout(client, states['releases']['url'], local_dir, url)
						release_version = states['releases']['name']

						if states['releases']['commit_time_raw'] < states['current']['commit_time_raw']:
							msg = "{0: <30} {1: <13} {2:} release is outdated (release: {3:} & current: {4:})"
							release_time_str = states['releases']['commit_time']
							current_time_str = states['current']['commit_time']
							msg = msg.format(protocol_name, data_name, release_version, release_time_str, current_time_str)

						else:
							msg = "{0: <30} {1: <13} {2:} is up to date".format(protocol_name, data_name, release_version)

					else:
						msg = "{0: <30} {1: <13} has no releases".format(protocol_name, data_name)

					logging.info(msg)
				else:
					logging.info("{0: <30} {1: <13} --IS A LINK--".format(protocol_name, data_name))
					protocol_path = os.path.join(local_dir, protocol_name)
					if not os.path.isdir(protocol_path):
						os.mkdir(protocol_path)
					checkout(client, data_info['url'], local_dir, url, False)
		else:
			logging.info("{0: <30} --IS A LINK--".format(protocol_name))
			checkout(client, protocol_info['url'], local_dir, url, False)


def get_states(client, url):
	states_data = {}

	states = simple_list(client, url)
	for state_name, state_info in states.items():

		if state_name == 'releases':
			newest_release = get_newest_release(client, state_info['url'])
			if newest_release != {}:
				states_data[state_name] = newest_release

		elif state_name == 'current':
			states_data[state_name] = state_info

	return states_data


def clean_checkout_path(checkout_path):
	if checkout_path is not None:
		for root, dirs, files in os.walk(checkout_path, topdown=False):
			for current_file in files:
				os.remove(os.path.join(root, current_file))
			for current_dir in dirs:
				full_path = os.path.join(root, current_dir)
				if os.path.islink(full_path):
					os.remove(full_path)
				else:
					os.rmdir(full_path)


def checkout(client, url, base_dir, svn_repo, is_directory=True):
	if base_dir is not None:
		section_path = left_strip(str_replace(url, svn_repo, ''), '/')
		basedir = right_strip(base_dir, '/')

		full_checkout_path = os.path.join(basedir, section_path)
		client.export(url, full_checkout_path, recurse=is_directory)


def clean_checkout(local_checkout):
	if local_checkout is not None:
		exclude_dir_patterns = [
			re.compile("^\..*"),
		]
		exclude_file_patterns = [
			re.compile("^\..*"),
			re.compile(".*\.pyc"),
			re.compile(".*\.doc"),
			re.compile(".*\.docx"),
		]

		for current_path, directories, files in os.walk(local_checkout):
			for current_file in files:
				if os.path.islink(os.path.join(current_path, current_file)):
					continue
				for file_pattern in exclude_file_patterns:
					if file_pattern.match(current_file) is not None:
						os.remove(os.path.join(current_path, current_file))
						# files.remove(current_file)
						break
			for current_directory in directories:
				if os.path.islink(os.path.join(current_path, current_directory)):
					directories.remove(current_directory)
					continue
				for dir_pattern in exclude_dir_patterns:
					if dir_pattern.match(current_directory) is not None:
						shutil.rmtree(os.path.join(current_path, current_directory), True)
						# directories.remove(current_directory)
						break
	return


def archive_ncd_files(output_filename, local_checkout):
	def exclude(tarinfo):
		exclude_patterns = [
			'.svn',
			'.pyc',
			'.DS_Store',
			'.doc',
			'.docx',
			'betas.txt',
			'fabfile',
			'fabprefs',
			'migrations',
			'.sass',
			'apache',
			'local_settings'
		]
		return_object = tarinfo
		for pattern in exclude_patterns:
			if pattern in tarinfo.name:
				return_object = None
		return return_object

	working_dir = os.getcwd()
	os.chdir(local_checkout)

	tar_filename = "{0:}.tar".format(output_filename)
	with tarfile.open(name=tar_filename, mode='w') as tar_file:
		for item in sorted(os.listdir(local_checkout)):
			tar_file.add(item, recursive=True, filter=exclude)

	zip_filename = "{0:}.tar.zip".format(output_filename)
	zipped_file = zipfile.ZipFile(file=zip_filename, mode='w', compression=zipfile.ZIP_DEFLATED)
	short_tar_filename = os.path.split(tar_filename)[1]
	zipped_file.write(tar_filename, arcname=short_tar_filename)
	zipped_file.close()

	os.remove(tar_filename)

	os.chdir(working_dir)


def main():
	module = AnsibleModule(
		argument_spec={
			'svn_username':                  {'type': 'str', 'required': True, },
			'svn_password':                  {'type': 'str', 'required': True, },
			'ncd_release_repo':              {'type': 'str', 'required': True, },
			'new_releases_file':             {'type': 'str', },
			'local_checkout_dir':            {'type': 'str', },
			'releases_status_logfile':       {'type': 'str', 'default': 'ncd_repo_status'},
			'releases_status_logfile_level': {
				'choices': ['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL', ],
				'default': 'DEBUG'
			},
		},
	)

	logging_modes = {
		'DEBUG':    logging.DEBUG,
		'INFO':     logging.INFO,
		'WARNING':  logging.WARNING,
		'ERROR':    logging.ERROR,
		'CRITICAL': logging.CRITICAL,
	}

	svn_user = module.params['svn_username']
	svn_pass = module.params['svn_password']
	ncd_release_repo = module.params['ncd_release_repo']
	new_releases_file = module.params['new_releases_file']
	local_checkout_dir = module.params['local_checkout_dir']
	releases_status_logfile = module.params['releases_status_logfile']
	releases_status_logfile_level = module.params['releases_status_logfile_level']

	if new_releases_file is not None:
		new_releases_file = os.path.expanduser(new_releases_file)
	if local_checkout_dir is not None:
		local_checkout_dir = os.path.expanduser(local_checkout_dir)
	if releases_status_logfile is not None:
		releases_status_logfile = os.path.expanduser(releases_status_logfile)

	start_time = datetime.today()

	fmt_time = start_time.strftime("%Y-%m-%d~%I:%M%p")
	setup_logging(releases_status_logfile, fmt_time, logging_modes[releases_status_logfile_level])

	def callback_ssl_server_trust_prompt(trust_dict):
		return True, trust_dict['failures'], True

	def callback_get_login(realm, username, may_save):
		return True, svn_user, svn_pass, False

	py_svn_client = pysvn.Client()
	py_svn_client.callback_ssl_server_trust_prompt = callback_ssl_server_trust_prompt
	py_svn_client.callback_get_login = callback_get_login

	# =============================================================================================
	# Tags any new releases specified in the beta release file if the file is specified.
	if new_releases_file is not None:
		tag_new_releases(py_svn_client, ncd_release_repo, new_releases_file)
		# Moves the beta release file so if the command is reran it will not re-release what was released.
		file_name, extension = new_releases_file.split('.', 2)
		moved_release_file = "{0:}_{1:}.{2:}".format(file_name, fmt_time, extension)
		os.rename(new_releases_file, moved_release_file)
	tag_finish_time = datetime.today()

	# =============================================================================================
	# Clean checkout directory if a local dir is specified.
	clean_checkout_path(local_checkout_dir)
	clean_finish_time = datetime.today()

	# =============================================================================================
	# Scan protocols status and checkout/export files if a local dir is specified.
	scan_protocols(py_svn_client, ncd_release_repo, local_checkout_dir)
	checkout_finish_time = datetime.today()
	clean_checkout(local_checkout_dir)
	clean_checkout_finish_time = datetime.today()

	# =============================================================================================
	# Send run time information to the logging module.
	logging.debug("Start time: {0:}".format(start_time))
	logging.debug("End time:   {0:}".format(clean_checkout_finish_time))
	if new_releases_file is not None:
		logging.debug("Tag new releases duration:       {0:}".format(tag_finish_time - start_time))

	if local_checkout_dir is not None:
		logging.debug("Clean checkout dir duration:     {0:}".format(clean_finish_time - tag_finish_time))
		logging.debug("SVN export duration of releases: {0:}".format(checkout_finish_time - clean_finish_time))
		logging.debug("Clean release duration:          {0:}".format(clean_checkout_finish_time - checkout_finish_time))
	else:
		logging.debug("SVN checking of releases:        {0:}".format(checkout_finish_time - clean_finish_time))

	logging.debug("Total run time duration:         {0:}".format(clean_checkout_finish_time - start_time))

	module.exit_json(
		changed=True,
		# msg="generated new compressed file",
	)

main()
