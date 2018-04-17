#!/usr/bin/python

# Standard python modules to import
import datetime
import os
import os.path

# 3rd party python modules to import
# None

# NovaTech python modules to import
# None

# This is a list of directories that the script will remove any files in the directory, but leave any directories and
#   files in those subdirectories.
DEFAULT_DIRECTORIES = [
	"/opt/iso_temp_files", # Directory for the Build System
	"/opt/zip_temp_files", # Directory for the Support Site
]
DEFAULT_MINUTE_COUNT = 30


def remove_files(directories=DEFAULT_DIRECTORIES, minute_count=DEFAULT_MINUTE_COUNT, test=False):
	modified_timedelta = datetime.timedelta(minutes=minute_count)
	current_time = datetime.datetime.now()
	for scan_directory in directories:
		if os.path.isdir(scan_directory):
			directory_entries = os.listdir(scan_directory)
			for entry in directory_entries:
				full_name = os.path.join(scan_directory, entry)
				if os.path.isfile(full_name):
					modified_time_epoch = os.path.getmtime(full_name)
					modified_time = datetime.datetime.fromtimestamp(modified_time_epoch)
					time_since_change = (current_time - modified_time)

					if time_since_change > modified_timedelta:
						if test:
							print "Would remove '{0: <60}' ({1:}).".format(full_name, modified_time)
						else:
							os.remove(full_name)


if __name__ == "__main__":
	import argparse
	parser = argparse.ArgumentParser()
	parser.add_argument(
		"-m", "--minute_count",
		help="Count of how many minutes old a file needs to be before the file is removed (default: {0:}).".format(DEFAULT_MINUTE_COUNT),
		default=DEFAULT_MINUTE_COUNT,
		required=False,
		type=int,
	)
	parser.add_argument(
		"-d", "--directories",
		help="Overwrite the directory to scan and remove files from (default: {0:}).".format(DEFAULT_DIRECTORIES),
		default=DEFAULT_DIRECTORIES,
		nargs='*',
		required=False,
	)
	parser.add_argument(
		"-t", "--test",
		help="Only print out file names the would have been removed.",
		default=False,
		required=False,
		action="store_true",
	)
	arguments = vars(parser.parse_args())
	remove_files(**arguments)
