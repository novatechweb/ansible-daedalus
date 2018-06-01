#!/usr/bin/env python2

import os
import sys
import re

for arg in sys.argv[1:]:
	#print "arg: %s" % arg
	first_path = arg
	
	#print "replacedates.py: %s" % (first_path)
	
	first_file = open(first_path)
	first_data = first_file.read()
	first_file.close()
	
	orig_data = first_data
	
	#Mon Nov 31 13:00:34 CST 2008
	p = re.compile('[A-Z][a-z]{2,2} [A-Z][a-z]{2,2} [0-3 ][0-9] [0-9]{2,2}:[0-9]{2,2}:[0-9]{2,2} [A-Z]{3,3} 2[0-9]{3,3}')
	first_data = p.sub( 'DDD MMM DD HH:MM:SS ZZZ YYYY', first_data)
		
	#Nov 10 2008
	p = re.compile('[A-Z][a-z]{2,2} [0-3 ][0-9] 2[0-9]{3,3}')
	first_data = p.sub( 'MMM DD YYYY', first_data)
	
	#16:30:17
	p = re.compile('[0-2][0-9]:[0-5][0-9]:[0-5][0-9]')
	first_data = p.sub( 'HH:MM:SS', first_data)
		
	if first_path.endswith('.pyo'):
		first_data = first_data[0:4] + 'SSSS' + first_data[8:]
		
	if orig_data != first_data:
		first_file = open(first_path, 'w')
		first_file.write(first_data)
		first_file.close()
		
