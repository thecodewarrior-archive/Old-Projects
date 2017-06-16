#!/usr/bin/env python3.2

from subprocess import call #Popen , PIPE
import sys
def ScrapedLen():
	call(['grep' , '-c' , '\n' , sys.argv[1]])# , stdout=PIPE)
#	lns = int(pop.communicate())
#	print(round(lns, -3))
	
if __name__ == '__main__':
	ScrapedLen()
